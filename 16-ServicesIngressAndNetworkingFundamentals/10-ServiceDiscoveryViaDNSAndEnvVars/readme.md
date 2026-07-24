# Service Discovery via DNS & Env Vars

This lesson is about **how a client Pod finds a Service** — not how a Service finds its Pods (that is the Service `selector` + Endpoints from earlier lessons).

Service discovery lets containers connect to dependencies **without hard-coding unstable Pod IPs**. Kubernetes gives each Service a stable ClusterIP and DNS name; discovery is how your app learns that address.

## DNS-Based Discovery (preferred)

When a Service is created, **CoreDNS** registers a DNS record. Each Service gets a **Fully Qualified Domain Name (FQDN)**:

```text
<service>.<namespace>.svc.cluster.local
```

- Pods in the **same namespace** can use just the short name (`<service>`).
- Cross-namespace access requires the FQDN (or at least `<service>.<namespace>`).

Cluster DNS resolves the name to the Service's ClusterIP, which routes to the target Pods.

## Environment Variable Discovery (legacy)

When a Pod is **created**, the **kubelet** automatically injects environment variables for every Service that **already exists** in that Pod's namespace. You do **not** declare these in your Pod YAML — they appear inside the container at runtime.

### Naming rule

Take the Service name, uppercase it, replace `-` with `_`, then add the suffix:

| Service name | Injected variables (the ones apps actually use) |
|---|---|
| `backend-api` | `BACKEND_API_SERVICE_HOST`, `BACKEND_API_SERVICE_PORT` |
| `mysql` | `MYSQL_SERVICE_HOST`, `MYSQL_SERVICE_PORT` |
| `redis-cache` | `REDIS_CACHE_SERVICE_HOST`, `REDIS_CACHE_SERVICE_PORT` |

Kubernetes also injects extra `*_PORT_*_TCP_*` variables (shown in `printenv`); legacy apps typically read only `*_SERVICE_HOST` and `*_SERVICE_PORT`.

### DNS vs env var — same destination, different lookup

```text
# DNS (hostname → ClusterIP resolved by CoreDNS)
wget http://backend-api

# Env vars (IP + port read from shell environment)
wget http://${BACKEND_API_SERVICE_HOST}:${BACKEND_API_SERVICE_PORT}
```

Both hit the same ClusterIP. DNS uses a name; env vars use the IP the kubelet wrote into the container environment.

**Key drawback:** if a Service is created *after* the Pod, the Pod must be **restarted** to see the new variables. Prefer DNS unless you must support legacy apps.

## Demo Files

| File | Purpose |
|------|---------|
| `backend-and-service.yaml` | nginx Deployment + `backend-api` ClusterIP Service |
| `client-pod.yaml` | Busybox Pod for DNS tests (`wget http://backend-api`) |
| `legacy-client-pod.yaml` | Busybox Pod that connects using `$BACKEND_API_SERVICE_HOST` only |

## Step 1: Deploy the Service First

Apply the backend **before** the client Pod — env vars are only injected for Services that already exist when the Pod starts.

```bash
kubectl apply -f backend-and-service.yaml
kubectl get svc backend-api
```

Note the `CLUSTER-IP` (e.g. `10.96.x.x`). You will see this same address from DNS and from env vars.

## Step 2: DNS Discovery

Create the client Pod, then resolve the Service by name:

```bash
kubectl apply -f client-pod.yaml
kubectl wait --for=condition=ready pod/discovery-client --timeout=60s
```

**Short name** (same namespace):

```bash
kubectl exec discovery-client -- nslookup backend-api
```

**FQDN** (works from any namespace):

```bash
kubectl exec discovery-client -- nslookup backend-api.default.svc.cluster.local
```

Both should return the Service's ClusterIP. Connect over HTTP using the short name:

```bash
kubectl exec discovery-client -- wget -qO- http://backend-api
```

You should see the nginx welcome page HTML.

## Step 3: Environment Variable Discovery

### 3a. See what the kubelet injected

When `discovery-client` started, the kubelet saw `backend-api` already existed and injected env vars automatically:

```bash
kubectl exec discovery-client -- printenv | grep BACKEND_API
```

Example output:

```text
BACKEND_API_SERVICE_HOST=10.96.x.x    ← ClusterIP (this is what apps use)
BACKEND_API_SERVICE_PORT=80           ← Service port (this is what apps use)
BACKEND_API_PORT=tcp://10.96.x.x:80
BACKEND_API_PORT_80_TCP=tcp://10.96.x.x:80
BACKEND_API_PORT_80_TCP_ADDR=10.96.x.x
BACKEND_API_PORT_80_TCP_PORT=80
BACKEND_API_PORT_80_TCP_PROTO=tcp
```

Compare with the Service ClusterIP — they match:

```bash
kubectl get svc backend-api -o jsonpath='ClusterIP: {.spec.clusterIP}{"\n"}'
kubectl exec discovery-client -- sh -c 'echo "Env var:  $BACKEND_API_SERVICE_HOST"'
```

### 3b. Connect using env vars (no DNS hostname)

Deploy a client that **never uses the name `backend-api`** — only the injected variables:

```bash
kubectl apply -f legacy-client-pod.yaml
kubectl wait --for=condition=ready pod/legacy-client --timeout=60s
kubectl logs legacy-client
```

You should see output like:

```text
=== Legacy env-var discovery (no DNS hostname used) ===
BACKEND_API_SERVICE_HOST=10.96.x.x
BACKEND_API_SERVICE_PORT=80
Fetching http://10.96.x.x:80 ...
<!DOCTYPE html>
<html>
<head>
...
```

The container command in `legacy-client-pod.yaml` is the whole point — a legacy app does this in code:

```bash
# pseudocode — same idea in Python, Java, etc.
host = os.environ["BACKEND_API_SERVICE_HOST"]
port = os.environ["BACKEND_API_SERVICE_PORT"]
connect(host, port)
```

Step 2 used `http://backend-api` (DNS). Step 3b uses `http://$BACKEND_API_SERVICE_HOST:$BACKEND_API_SERVICE_PORT` (env vars). Same backend, two ways to find it.

## Step 4: Cross-Namespace DNS

Create a Service in another namespace and reach it by FQDN from `discovery-client`:

```bash
kubectl create namespace data

kubectl create deployment db --image=nginx:stable -n data
kubectl expose deployment db --port=80 -n data
```

Resolve using the namespace-qualified name:

```bash
kubectl exec discovery-client -- nslookup db.data.svc.cluster.local
kubectl exec discovery-client -- wget -qO- http://db.data.svc.cluster.local
```

The short name `db` does **not** work from `default` — only `db.data` or the full FQDN.

## Step 5: Env Var Timing Trap

Env vars are fixed at Pod creation. Create a new Service **after** the client Pod is running:

```bash
kubectl create deployment cache --image=nginx:stable
kubectl expose deployment cache --port=80
```

The running client Pod has **no** `CACHE_*` variables:

```bash
kubectl exec discovery-client -- printenv | grep CACHE || echo "no CACHE env vars"
```

Recreate the Pod so the kubelet injects them:

```bash
kubectl delete pod discovery-client
kubectl apply -f client-pod.yaml
kubectl wait --for=condition=ready pod/discovery-client --timeout=60s
kubectl exec discovery-client -- printenv | grep CACHE_SERVICE
```

DNS would have worked immediately without a restart — that is why DNS is preferred.

## DNS vs Environment Variables

| | DNS | Environment variables |
|--|-----|-----------------------|
| Flexibility | Simple hostnames, cross-namespace via FQDN | Same-namespace only |
| Headless services | Returns multiple Pod IPs | Not supported |
| Timing | Works anytime | Only populated at **Pod creation** |
| Main use | Modern default | Backward compatibility |

## Cleanup

```bash
kubectl delete -f legacy-client-pod.yaml -f client-pod.yaml -f backend-and-service.yaml
kubectl delete deployment cache --ignore-not-found
kubectl delete svc cache --ignore-not-found
kubectl delete deployment db -n data --ignore-not-found
kubectl delete svc db -n data --ignore-not-found
kubectl delete namespace data --ignore-not-found
```

## CKAD Tips

- Memorize the FQDN pattern: `service.namespace.svc.cluster.local`.
- Same namespace → short name works; different namespace → include the namespace.
- Env-var discovery only reflects Services that existed **before** the Pod started; you never put them in the Pod YAML — the kubelet injects them.
- Service `backend-api` → `BACKEND_API_SERVICE_HOST` + `BACKEND_API_SERVICE_PORT` (uppercase, `-` → `_`).
- Env vars are **background knowledge** for CKAD; DNS/FQDN is what you need to know cold.
- Debug DNS with `kubectl exec <pod> -- nslookup <service>` or a temporary busybox Pod.

## Key Takeaway

Use DNS for service discovery: short names within a namespace, FQDNs across namespaces. Environment variables are a legacy fallback limited to same-namespace Services that exist before the Pod is created.
