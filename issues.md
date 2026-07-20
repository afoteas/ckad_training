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

## kubectl top Reports "no metrics available" on kind

### Issue

On kind clusters, `kubectl top pod` and `kubectl top node` return errors or show no data:

```bash
$ kubectl top node
error: Metrics not available yet.

$ kubectl top pod
error: unable to compute resource metrics from pods: not all metrics are ready for pods
```

This blocks profiling and performance analysis on local clusters.

### Root Cause

kind clusters do not come with the Metrics Server preinstalled. The Metrics Server is a core Kubernetes component that collects resource usage data from kubelet and cAdvisor on each node and makes it available via the Metrics API. Without it, `kubectl top` has no data source.

Additionally, kind nodes run as Docker containers using self-signed certificates, so the Metrics Server's TLS validation must be disabled.

### Applied Solution

1. Install Metrics Server:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. Patch the Metrics Server deployment to disable TLS validation (required for kind's self-signed certs):

   ```bash
   kubectl patch deployment metrics-server -n kube-system --type='json' \
     -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-insecure-tls"}]'
   ```

3. Patch to ensure the Metrics Server can find the kubelet on the correct address:

   ```bash
   kubectl patch deployment metrics-server -n kube-system --type='json' \
     -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--kubelet-preferred-address-types=InternalIP"}]'
   ```

4. Wait for the deployment to roll out:

   ```bash
   kubectl rollout status deployment/metrics-server -n kube-system
   ```

5. Wait an additional 30 seconds for initial metrics collection, then test:

   ```bash
   kubectl top node
   kubectl top pod --all-namespaces
   ```

### Verification

```bash
# Confirm Metrics Server is running
kubectl get deployment metrics-server -n kube-system

# Confirm metrics are available
kubectl top node
kubectl top pod -A

# Check Metrics Server logs if still failing
kubectl logs -n kube-system deployment/metrics-server
```

Result: `kubectl top` commands now display CPU and memory usage for all nodes and pods.

### Notes

- Metrics Server requires a Linux node environment; on Windows-based minikube, it may not function fully.
- This setup is only needed once per kind cluster; deleting and recreating the cluster requires re-running these steps.
- If metrics still do not appear after 30 seconds, check Metrics Server logs for TLS or connection errors.
- For production clusters (EKS, GKE, AKS), Metrics Server is pre-installed and these steps are not needed.

## Argo CD Repo Sync Fails with Zscaler TLS Error

### Issue

Behind the Zscaler TLS-inspecting proxy, Argo CD fails to read the Git repository and
the Application shows:

- `failed to list refs: ... tls: failed to verify certificate: x509: certificate signed by unknown authority`

Example source URL that failed:

```text
https://github.com/argoproj/argocd-example-apps/info/refs?service=git-upload-pack
```

### Root Cause

Argo CD runs its Git operations inside the `argocd-repo-server` pod, which uses its own
container trust store — not the WSL2 host trust store. Zscaler re-signs the connection to
`github.com` with its own root CA, which the repo-server does not trust by default, so
`git ls-remote` fails certificate verification.

### Applied Solution

Argo CD reads per-repository-host TLS certificates from the `argocd-tls-certs-cm`
ConfigMap in the `argocd` namespace, keyed by hostname. Inject the Zscaler root CA for
`github.com`:

1. Add the Zscaler root CA for the `github.com` host. Easiest with the Argo CD CLI:

   ```bash
   argocd cert add-tls github.com --from ~/certs/zscaler-root-ca.crt --upsert
   ```

   Or, without the CLI, load it straight into the ConfigMap with `kubectl`:

   ```bash
   kubectl -n argocd create configmap argocd-tls-certs-cm \
     --from-file=github.com=$HOME/certs/zscaler-root-ca.crt \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

2. Restart the repo-server so it reloads the mounted certificate:

   ```bash
   kubectl -n argocd rollout restart deploy argocd-repo-server
   kubectl -n argocd rollout status deploy argocd-repo-server --timeout=120s
   ```

3. Force a hard refresh of the Application:

   ```bash
   kubectl -n argocd patch application nginx-app --type merge \
     -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
   ```

For multiple Git hosts, add one key per hostname (for example `raw.githubusercontent.com`).
When installing via Helm, the same certs can be provided declaratively through the chart's
`configs.tls.certificates` values so they survive upgrades.

### Verification

```bash
# No TLS error should remain in the Application conditions
kubectl -n argocd get application nginx-app -o jsonpath='{.status.conditions}'; echo

# Sync status should now be readable (e.g. OutOfSync/Synced), not Unknown with a TLS error
kubectl -n argocd get application nginx-app \
  -o jsonpath='Sync={.status.sync.status} Health={.status.health.status}'; echo
```

Result: the `x509: certificate signed by unknown authority` error disappears and Argo CD
can list refs and generate manifests from the repository.

### Notes

- This is the secure alternative to `--insecure-skip-server-verification`; certificate
  verification stays enabled, only the corporate CA is trusted.
- Only the Zscaler root CA is required here because Zscaler re-signs with that root; if an
  intermediate is presented, append it to the same PEM value.
- The `argocd-tls-certs-cm` key must be the exact hostname (no scheme, no path).
