# Deploying NGINX Ingress and Basic Routing

This lesson installs the widely used **NGINX ingress controller** and defines an **Ingress resource** to expose an application via a hostname-based rule.

For the controller-vs-resource theory, see [05-IngressControllersAndResources](../05-IngressControllersAndResources/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `nginx-deployment.yaml` | Target `web-app` Deployment (from lesson 02) |
| `clusterip-service.yaml` | `internal-api` ClusterIP Service (from lesson 02) |
| `nginx-ingress.yaml` | Ingress routing `demo.kube.com` → `internal-api:80` |

## Why Ingress Instead of NodePort

A NodePort exposes one Service per port on every node's IP. Ingress is a Layer 7 HTTP/HTTPS router that sends traffic to **multiple backend Services** by request **hostname or path** — behind a single public IP.

## Step 1: Install the NGINX Ingress Controller

The controller watches for Ingress resources and configures the NGINX reverse proxy. Install it with the official manifest:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

This creates all resources (Deployment, Services, roles, etc.) in the `ingress-nginx` namespace.

### Verify the installation

```bash
kubectl get pods --namespace=ingress-nginx -w
```

Wait until the controller Pod shows `Running`. Two `*-admission-*` Pods showing `Completed` is expected (they are one-off setup jobs).

## Step 2: Deploy the Target Application

If not already deployed from lesson 02:

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f clusterip-service.yaml
```

## Step 3: Create the Ingress Rule

```bash
kubectl apply -f nginx-ingress.yaml
kubectl get ingress
```

The rule routes traffic for hostname `demo.kube.com` to the `internal-api` ClusterIP Service.

## Step 4: Test

Since you do not own `demo.kube.com`, either add it to your hosts file pointing at the controller IP, or send a `Host` header:

```bash
# Option A: hosts file entry, then:
curl http://demo.kube.com

# Option B: force the Host header against the controller IP
curl -H "Host: demo.kube.com" http://<ingress-controller-ip>/
```

You should be routed through the NGINX controller to the `internal-api` Service.

## How Traffic Flows

```text
client → NGINX ingress controller → (host: demo.kube.com) → internal-api (ClusterIP) → web-app Pods
```

## Cleanup

```bash
kubectl delete -f nginx-ingress.yaml
kubectl delete -f clusterip-service.yaml -f nginx-deployment.yaml
```

## CKAD Tips

- Set `ingressClassName: nginx` so the NGINX controller claims the resource.
- The backend Service is usually a **ClusterIP** — Ingress fronts it, no NodePort needed.
- Test routing with `curl -H "Host: <name>"` when you can't edit DNS.

## Key Takeaway

Install an ingress controller once, then declare Ingress resources to route external HTTP traffic by hostname (and path) to internal ClusterIP Services — all behind a single entry point.
