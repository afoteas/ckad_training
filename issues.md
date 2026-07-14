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
minikube ssh "docker pull nginx:stable"
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
  separate WSL2 inotify/file-descriptor limit issue.
