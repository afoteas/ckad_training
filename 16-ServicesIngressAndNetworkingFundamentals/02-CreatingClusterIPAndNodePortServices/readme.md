# Creating ClusterIP and NodePort Services

This lesson exposes a simple nginx application using two core Service types: **ClusterIP** for internal-only access and **NodePort** for external access.

For the concepts behind each Service type, see [01-ServiceTypesExplained](../01-ServiceTypesExplained/readme.md).

## Demo Files


| File                     | Purpose                                                       |
| ------------------------ | ------------------------------------------------------------- |
| `nginx-deployment.yaml`  | nginx Deployment (2 replicas, port 80) labeled `app: web-app` |
| `clusterip-service.yaml` | `internal-api` ClusterIP Service                              |
| `nodeport-service.yaml`  | `external-web` NodePort Service on `30080`                    |


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

## NodePort on Every Node

NodePort opens the port on **every** node, not only the node where a Pod runs. With the default `externalTrafficPolicy: Cluster`, you can hit **any** node's IP on the NodePort — kube-proxy on that node forwards traffic to a backend Pod, even on another node.

Example: 5 nodes, 1 replica on node-1:

```text
curl node-1:30080  →  works  →  pod on node-1
curl node-2:30080  →  works  →  kube-proxy forwards to pod on node-1
```

## externalTrafficPolicy

Controls how external traffic is routed once it hits a node. Applies to NodePort and LoadBalancer Services (see [03-LoadBalancerServicesAndExternalTrafficPolicy](../03-LoadBalancerServicesAndExternalTrafficPolicy/readme.md) for the LoadBalancer angle).

| Policy | NodePort behavior | Client IP |
|--------|-------------------|-----------|
| `Cluster` (default) | Any node accepts traffic; forwarded to Pods on **any** node | Hidden (NAT'd to the node IP) |
| `Local` | Only nodes with a **local** ready Pod accept traffic; others drop it | **Preserved** |

With `Local` and a single replica on one node, only that node's `<node-ip>:30080` works — the other four nodes will not forward cross-node.

```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Local
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

## Cleanup

```bash
kubectl delete -f nodeport-service.yaml -f clusterip-service.yaml -f nginx-deployment.yaml
```



## CKAD Tips

- `type: ClusterIP` can be omitted (it is the default).
- `port` is the Service port; `targetPort` is the container port; `nodePort` is the external node port.
- `nodePort` must be in **30000–32767** (or omit it to get one auto-assigned).
- NodePort is reachable on **every** node's IP (default `externalTrafficPolicy: Cluster`).
- `externalTrafficPolicy: Local` — only nodes running a backend Pod accept external traffic; preserves client source IP.
- `kubectl expose deployment web-app-deployment --port=80 --type=NodePort` is a fast imperative alternative.



## Key Takeaway

ClusterIP gives a stable internal endpoint for in-cluster communication; NodePort opens a static port on every node for external access. By default, any node can receive NodePort traffic and kube-proxy forwards it to backend Pods cluster-wide; use `externalTrafficPolicy: Local` when you need the real client IP or node-local routing only.