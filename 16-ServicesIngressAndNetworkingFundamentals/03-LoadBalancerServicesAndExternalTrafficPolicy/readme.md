# LoadBalancer Services and ExternalTrafficPolicy

The LoadBalancer Service type exposes production-grade applications to the public internet by provisioning a **cloud-managed load balancer** with a stable public IP.

For all Service types, see [01-ServiceTypesExplained](../01-ServiceTypesExplained/readme.md).

## Example File

- `loadbalancer-service.yaml` — LoadBalancer Service exposing port 80 → targetPort 8080

## Why LoadBalancer

Unlike NodePort (limited scalability), a cloud load balancer offers built-in health checks, high throughput, and high availability. It bridges internal Kubernetes networking and external cloud infrastructure.

## How It Works

```text
1. Define Service type: LoadBalancer (with a selector)
2. Controller manager calls the cloud API → creates an external LB + public IP
3. LB routes incoming traffic to a NodePort (≈30000 range) on active nodes
4. kube-proxy on the node forwards traffic to the target Pods
```

## Example

```yaml
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80          # LB listens here
    targetPort: 8080  # Pods listen here
```

The external LB listens on port 80 and forwards to Pods on 8080.

## ExternalTrafficPolicy

Controls how traffic is routed once it reaches a node — which affects **client source IP** preservation:

| Policy | Routing | Client IP | Load distribution |
|--------|---------|-----------|-------------------|
| `Cluster` (default) | To Pods on **any** node | Hidden (appears as node IP, due to NAT) | Even across all Pods |
| `Local` | Only to Pods on the **entry node** | **Preserved** (no NAT) | Uneven if Pods are unevenly spread |

### When to use each

- **Cluster** — maximize distribution; simplest for large clusters. Downside: hides client IP, harder request tracing.
- **Local** — preserve client IP for IP-based security, geolocation, rate-limiting, or logging. Downside: risk of node-level hotspots.

## Operational and Cost Considerations

- **Cloud-only** — on bare metal/self-managed it stays `Pending` unless something like **MetalLB** is installed.
- **Cost** — each LoadBalancer provisions a dedicated billable cloud resource; many Services get expensive.
- **Multi-hop routing** (LB → NodePort → Pod) adds complexity and possible cross-node latency; `Cluster` NAT makes tracing harder.
- **Layer 4 only** — LoadBalancer does basic TCP/UDP. For Layer 7 features (URL routing, SSL termination, path routing) use an **Ingress**.

## CKAD Tips

- LoadBalancer stays `Pending` without cloud integration — expected locally.
- `externalTrafficPolicy: Local` preserves the client source IP.
- For HTTP host/path routing and TLS, reach for Ingress, not LoadBalancer.

## Key Takeaway

LoadBalancer is the go-to for public, scalable exposure on cloud clusters. Use `externalTrafficPolicy: Local` when you need the real client IP, and switch to Ingress when you need Layer 7 routing.
