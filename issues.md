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

## Testing Ingress on kind + WSL2 without port-forward

### Issue

Lesson 06 suggests testing with `curl http://demo.kube.com`, but on a local kind cluster
behind WSL2 (and often Zscaler) this fails even after installing ingress-nginx:

- `demo.kube.com` does not resolve without a hosts entry
- `curl http://demo.kube.com` uses port **80**, but nothing on the host listens there
- The ingress controller's HTTP **nodePort** (auto-assigned, e.g. `31105`) is not published
  to the host — only the port in the kind config is (see `kind-multi-node-config.yaml`:
  `hostPort: 8080` → `containerPort: 30080`)

### Root Cause

Four separate problems must be solved:

1. **DNS** — map `demo.kube.com` to `127.0.0.1` via `/etc/hosts` (WSL2 Linux file, not
   Windows, when curling from inside WSL).
2. **Host entry point** — kind publishes `localhost:8080` → node port `30080` only.
3. **Ingress wiring** — the ingress-nginx controller Service must use **nodePort `30080`**
   for HTTP so traffic hitting `localhost:8080` reaches the controller.
4. **`externalTrafficPolicy: Local` from the install manifest** — lesson 06 installs
   ingress-nginx from the upstream **cloud** manifest:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```

   That remote YAML defines the `ingress-nginx-controller` Service with
   `externalTrafficPolicy: Local` (not in your local `nginx-ingress.yaml` — it is baked
   into the install manifest's Service spec). On real cloud clusters this preserves the
   client source IP. On kind it breaks host access when:

   - kind `extraPortMappings` publish port `30080` on the **control-plane** only, and
   - the controller Pod is scheduled on a **worker** node (common on multi-node clusters).

   With `Local`, NodePort traffic is only handled by nodes that have a **local** controller
   Pod. Traffic from the host hits the control-plane on `:8080` → nodePort `30080`, finds
   no local endpoint, and **hangs** (TCP connects, HTTP never responds). Curl from inside
   the control-plane container (`docker exec ... curl 127.0.0.1:30080`) may still work
   because that path is not treated the same as external NodePort traffic.

A hosts file alone cannot fix the port mismatch or the `Local` policy issue.

### Applied Solution

1. Add a hosts entry **inside WSL2**:

   ```bash
   sudo nano /etc/hosts
   ```

   Add:

   ```text
   127.0.0.1  demo.kube.com
   ```

   Verify:

   ```bash
   getent hosts demo.kube.com
   ```

2. Patch the ingress controller Service so HTTP uses nodePort `30080` (matches kind's
   `extraPortMappings`):

   ```bash
   kubectl patch svc ingress-nginx-controller -n ingress-nginx --type='json' -p='[
     {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}
   ]'
   ```

   Confirm:

   ```bash
   kubectl get svc -n ingress-nginx ingress-nginx-controller
   # PORT(S) should include 80:30080/TCP
   ```

   **Collision check:** if lesson 02's `external-web` NodePort Service still uses
   `30080`, delete it first or change one of the Services to a different nodePort:

   ```bash
   kubectl delete svc external-web
   # or: kubectl patch svc external-web --type='json' -p='[
   #   {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30081}
   # ]'
   ```

3. Change `externalTrafficPolicy` from `Local` to `Cluster` on the controller Service
   (required on kind when the controller Pod is not on the control-plane node):

   ```bash
   kubectl patch svc ingress-nginx-controller -n ingress-nginx \
     -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
   ```

   Verify:

   ```bash
   kubectl get svc ingress-nginx-controller -n ingress-nginx \
     -o jsonpath='{.spec.externalTrafficPolicy}{"\n"}'
   # should print: Cluster
   ```

   Inspect where the setting came from (upstream manifest, not your Ingress resource):

   ```bash
   kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml | grep externalTrafficPolicy
   ```

4. Deploy the demo app and Ingress (lesson 06 manifests):

   ```bash
   kubectl apply -f nginx-deployment.yaml -f clusterip-service.yaml -f nginx-ingress.yaml
   kubectl get ingress
   ```

5. Bypass Zscaler proxy for localhost (if `http_proxy`/`https_proxy` are set):

   ```bash
   export NO_PROXY=demo.kube.com,localhost,127.0.0.1
   curl --noproxy demo.kube.com http://demo.kube.com:8080
   ```

   Port `8080` is required because kind maps host `8080` → node `30080`, not host `80`.
   Ingress routes on the **Host header** (`demo.kube.com`), so `:8080` in the URL is fine.

### Verification

```bash
# Controller healthy
kubectl get pods -n ingress-nginx

# Ingress rule present
kubectl get ingress demo-ingress

# Should return nginx welcome page
curl --noproxy demo.kube.com http://demo.kube.com:8080
```

### Notes

- WSL2 may regenerate `/etc/hosts` on restart; for a persistent entry, set
  `generateHosts = false` in `/etc/wsl.conf` (optional for lab work).
- To use `curl http://demo.kube.com` with **no port** (true port 80), the kind cluster
  must be created with an extra mapping such as `hostPort: 80` → `containerPort: 30080`
  — the default config only maps `8080`.
- Alternative without hosts file: send the Host header explicitly —
  `curl -H "Host: demo.kube.com" http://localhost:8080` (still requires steps 2–3 above).
- `type: LoadBalancer` on the ingress controller stays `EXTERNAL-IP: <pending>` on kind;
  that is expected — NodePort + `extraPortMappings` is the local access path.
- Re-applying the upstream `deploy.yaml` will reset `externalTrafficPolicy` to `Local` and
  may reset the nodePort — re-run steps 2 and 3 after a fresh ingress-nginx install.
- Symptom of the `Local` policy issue: `curl` to `:8080` **connects** but **times out**
  with 0 bytes received; `docker exec ckad-control-plane curl -H "Host: demo.kube.com"
  http://127.0.0.1:30080` still returns 200.

## Cleaning up the cluster between practice runs

### Issue

After practice sessions the cluster accumulates leftover objects (Deployments, Services,
ConfigMaps, Secrets, PVCs, etc.) that interfere with the next run or make `kubectl get`
output noisy.

### Applied Solution

Options from targeted to nuclear:

1. **Wipe everything in the `default` namespace only:**

   ```bash
   kubectl delete all --all -n default
   kubectl delete configmap,secret,pvc,ingress,networkpolicy,sa --all -n default
   ```

   `all` covers pods, deployments, replicasets, statefulsets, daemonsets, services, jobs,
   cronjobs. It does **not** cover ConfigMaps, Secrets, PVCs, Ingress, NetworkPolicies, or
   ServiceAccounts — hence the second command.

2. **Delete specific practice namespaces** (removes everything inside them):

   ```bash
   kubectl delete namespace ckad-web ckad-config ckad-health ckad-batch \
     ckad-design ckad-rbac ckad-netpol ckad-storage
   ```

3. **Fully reset the cluster** (guaranteed clean — also wipes CNI, ingress, all namespaces):

   ```bash
   kind delete cluster --name ckad
   kind create cluster --name ckad --config <kind-config.yaml>
   ```

### Notes

- The default `kubernetes` Service and the `default` ServiceAccount are recreated
  automatically after deletion — do not worry about removing them.
- Avoid `kubectl delete all --all --all-namespaces`: it also targets `kube-system`
  workloads (CoreDNS, kindnet), briefly breaking cluster networking. Scope to your own
  namespaces instead.
- For a totally fresh slate before a timed mock exam, recreating the kind cluster
  (option 3) is the most reliable — no leftover CRDs, RBAC, or webhooks.

## git push fails: SSH blocked, need HTTPS + PAT

### Issue

`git push` over SSH fails on the restricted network. Port 22 is refused
(`connect to host github.com port 22: Connection refused`) and SSH-over-443
(`ssh.github.com:443`) is reset mid-handshake
(`kex_exchange_identification: read: Connection reset by peer`). A TLS-inspecting
proxy on the network permits only genuine HTTPS on 443 and kills tunnelled SSH, so
SSH cannot be used from this machine/policy.

### Applied Solution

Switch the remote to HTTPS and authenticate with a GitHub Personal Access Token (PAT).

1. **Create the PAT on GitHub** — Settings → Developer settings → Personal access tokens:
   - **Classic**: *Tokens (classic)* → *Generate new token (classic)* → check the **`repo`**
     scope → generate → copy it (starts with `ghp_...`).
   - **Fine-grained** (alternative): select the repo, set *Repository permissions →
     Contents: Read and write*. Copy the token (`github_pat_...`). You only see it once.

2. **Use the PAT at the push prompt** — paste the token as the *password* (not your
   account password); the paste is invisible in the terminal, which is normal:

   ```bash
   git remote set-url origin https://github.com/afoteas/<repo>.git
   git push --set-upstream origin main
   # Username: afoteas
   # Password: <paste the PAT>
   ```

3. **Save it so future pushes don't prompt:**

   ```bash
   git config --global credential.helper store          # persists to ~/.git-credentials
   # or, temporary in-memory cache:
   git config --global credential.helper 'cache --timeout=3600'
   ```

### Notes

- The tell for a TLS-inspection proxy is a **reset during `kex_exchange_identification`**
  on port 443 (TCP connects, then dies) versus a plain `Connection refused` on port 22.
- If HTTPS then throws an SSL cert error, trust the proxy's root CA (same Zscaler cert
  used elsewhere): `git config --global http.sslCAInfo /path/to/zscaler-root-ca.pem`.
  Use `http.sslVerify false` only as a last-resort temporary workaround.
- `gh auth login` (GitHub CLI) sets up the HTTPS credential helper automatically and
  avoids copying the PAT by hand.
- Switching WiFi may appear to "fix" SSH temporarily, but once the endpoint/proxy policy
  syncs, both networks block it — HTTPS + PAT is the durable fix.
