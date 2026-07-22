# Creating ClusterIP and NodePort Services

This lesson exposes a simple nginx application using two core Service types: **ClusterIP** for internal-only access and **NodePort** for external access.

For the concepts behind each Service type, see [01-ServiceTypesExplained](../01-ServiceTypesExplained/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `nginx-deployment.yaml` | nginx Deployment (2 replicas, port 80) labeled `app: web-app` |
| `clusterip-service.yaml` | `internal-api` ClusterIP Service |
| `nodeport-service.yaml` | `external-web` NodePort Service on `30080` |

## Pattern

- A backend (e.g. database) should be reached only by other Pods → **ClusterIP**.
- A frontend reached by users → **NodePort** (or, more commonly, LoadBalancer/Ingress).

This separation is a critical security and networking pattern.

## Step 1: Deploy the Application

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get pods -l app=web-app
```

Two Pods should be created.

## Step 2: Create the ClusterIP Service

```bash
kubectl apply -f clusterip-service.yaml
kubectl get svc internal-api
```

Note the `CLUSTER-IP` and that there is **no** `EXTERNAL-IP`. `type: ClusterIP` is the default, but is set explicitly here for clarity.

### Test internal access

Run a temporary Pod inside the cluster and curl the Service by name:

```bash
kubectl run curl-test -it --rm --image=curlimages/curl -- /bin/sh
# inside the Pod:
curl http://internal-api:80
```

You should see the nginx welcome page, then `exit`.

## Step 3: Create the NodePort Service

```bash
kubectl apply -f nodeport-service.yaml
kubectl get svc external-web
```

The `PORT(S)` column shows `80:30080/TCP` — port 80 inside, `30080` on every node.

### Test external access

Get a node IP, then curl it on the NodePort:

```bash
kubectl get nodes -o wide
curl http://<node-ip>:30080
```

On Docker Desktop the node IP may not be reachable directly — use `localhost` instead:

```bash
curl http://localhost:30080
```

Either way you should get the nginx welcome page.

## How Traffic Flows

```text
ClusterIP:  in-cluster client → internal-api (ClusterIP) → web-app Pods
NodePort:   external client → <node-ip>:30080 → kube-proxy → web-app Pods
```

## Cleanup

```bash
kubectl delete -f nodeport-service.yaml -f clusterip-service.yaml -f nginx-deployment.yaml
```

## CKAD Tips

- `type: ClusterIP` can be omitted (it is the default).
- `port` is the Service port; `targetPort` is the container port; `nodePort` is the external node port.
- `nodePort` must be in **30000–32767** (or omit it to get one auto-assigned).
- `kubectl expose deployment web-app-deployment --port=80 --type=NodePort` is a fast imperative alternative.

## Key Takeaway

ClusterIP gives a stable internal endpoint for in-cluster communication; NodePort opens a static port on every node for external access. Both select Pods via labels and forward to `targetPort`.
