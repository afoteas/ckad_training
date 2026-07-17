# Issues Log

## Installing the Zscaler Root CA into WSL2, minikube, and kind

### Issue

Behind a Zscaler TLS-inspecting proxy, image pulls fail with:

- `x509: certificate signed by unknown authority`

This happens because Zscaler re-signs TLS traffic with its own root CA, which the
WSL2 trust store, the minikube node, and the kind nodes do not trust by default.

### Root Cause

The Zscaler Root CA is present in the Windows certificate store but not in:

- the WSL2 (Linux) system trust store
- the minikube node's trust store / container runtime
- the kind node containers' trust store / containerd runtime

### Applied Solution

1. Export the Zscaler Root CA from the Windows machine store (via WSL interop):

   ```bash
   mkdir -p /mnt/c/Temp ~/certs
   powershell.exe -NoProfile -Command "\$c = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { \$_.Subject -match 'Zscaler Root CA' } | Select-Object -First 1; Export-Certificate -Cert \$c -FilePath 'C:\Temp\zscaler-root-ca.der' | Out-Null"
   cp /mnt/c/Temp/zscaler-root-ca.der ~/certs/
   ```

2. Convert DER to PEM in WSL2 and verify:

   ```bash
   openssl x509 -inform DER -in ~/certs/zscaler-root-ca.der -out ~/certs/zscaler-root-ca.crt
   openssl x509 -in ~/certs/zscaler-root-ca.crt -noout -subject -issuer -dates
   ```

3. Install into the WSL2 system trust store:

   ```bash
   sudo cp ~/certs/zscaler-root-ca.crt /usr/local/share/ca-certificates/zscaler-root-ca.crt
   sudo update-ca-certificates
   ```

4. Persist for future clusters and inject into the running minikube node:

   ```bash
   # Persist so `minikube start --embed-certs` picks it up on recreation
   mkdir -p ~/.minikube/certs
   cp ~/certs/zscaler-root-ca.crt ~/.minikube/certs/zscaler-root-ca.pem

   # Inject into the currently running node and restart its runtime
   minikube -p mini-ckad cp ~/certs/zscaler-root-ca.crt /usr/local/share/ca-certificates/zscaler-root-ca.crt
   minikube -p mini-ckad ssh "sudo update-ca-certificates && sudo systemctl restart docker"
   ```

5. Inject into every kind node container and restart containerd on each
   (kind nodes are Docker containers; the cluster here is named `ckad`):

   ```bash
   CERT=~/certs/zscaler-root-ca.crt
   for node in ckad-control-plane ckad-worker ckad-worker2 ckad-worker3; do
     docker cp "$CERT" "$node:/usr/local/share/ca-certificates/zscaler-root-ca.crt"
     docker exec "$node" update-ca-certificates
     docker exec "$node" systemctl restart containerd
   done
   ```

   List node names dynamically with `kind get nodes --name <cluster>` or
   `docker ps --format '{{.Names}}' | grep -E 'control-plane|worker'`.

### Verification

Minikube — pull the previously failing image from inside the node:

```bash
minikube -p mini-ckad ssh "docker pull nginx:stable"
```

kind — pull a Docker Hub image via containerd inside a node:

```bash
docker exec ckad-control-plane crictl pull docker.io/library/nginx:stable
```

Result: images pull successfully (no `x509` error), confirming the Zscaler CA is trusted
in both clusters.

### Notes

- For a clean recreation, start minikube with `--embed-certs` so `~/.minikube/certs` is trusted automatically.
- For kind, re-run the per-node loop after recreating the cluster, or bake the CA into a
  custom node image so it survives `kind create cluster`.
- Observed alongside this work: a node-level `Too many open files` warning, which is a
  separate WSL2 inotify/file-descriptor limit issue (see below).

## WSL2 inotify limits cause "Too many open files"

### Issue

On WSL2, Kubernetes/container operations fail intermittently with:

- `kube-proxy` crashing: `failed complete: too many open files`
- `systemctl` failing: `Failed to allocate directory watch: Too many open files`

This destabilizes minikube/kind nodes and blocks runtime restarts.

### Root Cause

This is not a disk or open-file-handle problem. WSL2 ships with low `inotify`
kernel limits (for example `fs.inotify.max_user_instances` often defaults to `128`).
Docker, minikube, kind, and VS Code each consume many inotify instances/watches,
exhausting the shared kernel limit. Because minikube/kind nodes are containers on the
same WSL2 kernel, they hit the same ceiling.

### Applied Solution

Raise the limits on the WSL2 host (kernel-level, so node containers benefit too):

```bash
# Temporary (current session)
sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=1048576

# Persistent (survives WSL restart)
echo -e "fs.inotify.max_user_instances=8192\nfs.inotify.max_user_watches=1048576" | sudo tee /etc/sysctl.d/99-inotify.conf
sudo sysctl -p /etc/sysctl.d/99-inotify.conf
```

Then restart the node runtime cleanly:

```bash
minikube -p mini-ckad ssh "sudo systemctl restart docker"
```

### Verification

```bash
# Confirm new limits are active
sysctl fs.inotify.max_user_instances fs.inotify.max_user_watches

# Core pods stay healthy (no CrashLoopBackOff on kube-proxy)
kubectl get pods -A
```

### Notes

- Applies to both minikube and kind since they share the WSL2 kernel.
- If limits reset after a full Windows reboot, confirm `/etc/sysctl.d/99-inotify.conf`
  is present and re-run `sudo sysctl -p /etc/sysctl.d/99-inotify.conf`.

## kind cluster becomes unreachable

### Issue

Cluster operations started failing because the kind API server became unreachable.
Common commands (for example `kubectl get`, `kubectl apply`, and `kubectl cluster-info`)
returned connection errors such as:

- `failed to download openapi`
- `dial tcp 127.0.0.1:<port>: connect: connection refused`

Example:

```bash
kubectl apply -f myapp-with-sidecar.yaml
```

This blocked normal cluster access and deployment workflows.

### Root Cause

The kind control-plane container (`ckad-control-plane`) had stopped (`Exited 128`),
while worker node containers were still running. kubeconfig contexts still pointed
to a localhost API server endpoint, but no API server process was listening there.

### Applied Solution

Used a non-destructive recovery instead of deleting/recreating the cluster:

1. Confirm control-plane status:

   ```bash
   docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep ckad-
   ```

2. Start the existing control-plane container:

   ```bash
   docker start ckad-control-plane
   ```

3. Retry kubectl commands:

   ```bash
   kubectl --context kind-ckad cluster-info
   kubectl --context kind-ckad get nodes
   ```

### Verification

```bash
kubectl --context kind-ckad cluster-info
kubectl --context kind-ckad get nodes
kubectl --context kind-ckad get pod myapp-with-sidecar -o wide
```

Result: cluster connectivity was restored and workloads were reachable/running again.

### Notes

- This error is usually control-plane availability, not an application manifest problem.
- `--validate=false` can bypass local schema validation, but it does not fix an
  unreachable API server.
- If the endpoint/credentials drift after restarts, refresh kubeconfig with:
  `kind export kubeconfig --name ckad`.
