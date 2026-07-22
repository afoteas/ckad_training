# Service Types Explained

A Service is the fundamental networking abstraction in Kubernetes: it gives ephemeral Pods a **stable, persistent endpoint** (a virtual IP and DNS name) and load-balances traffic across the Pods behind it.

For a hands-on ClusterIP/NodePort demo, see [02-CreatingClusterIPAndNodePortServices](../02-CreatingClusterIPAndNodePortServices/readme.md).

## The Problem Services Solve

When a Pod dies or is rescheduled to another node, its IP address changes. Other applications cannot reliably track it. A Service sits between clients and backend Pods, providing:

- A stable **ClusterIP** and DNS name that never change.
- Automatic **load balancing** across ready Pods.

## The Four Service Types

| Type | Primary purpose | Key characteristic |
|------|-----------------|--------------------|
| **ClusterIP** | Internal service-to-service communication | Internal-only IP; the **default** type |
| **NodePort** | Quick external exposure (testing) | Opens a static port (30000–32767) on **every** node |
| **LoadBalancer** | Internet-ready, scalable exposure | Provisions a cloud load balancer with a public IP |
| **ExternalName** | Connect internal workloads to external targets | Maps to an external DNS **CNAME**; no proxy or ClusterIP |

## ClusterIP (default)

- Reachable only **from within** the cluster.
- The backbone of microservice-to-microservice communication.
- If no `type` is specified, Kubernetes defaults to ClusterIP.

## NodePort

- Simplest way to allow external traffic in.
- Exposed on a port (typically 30000–32767) on **every node**.
- Users hit `<any-node-IP>:<nodePort>`; the node tunnels traffic to backend Pods.
- Not scalable/robust enough for public production — often used as a building block for LoadBalancers and Ingress.

## LoadBalancer

- Integrates with cloud infrastructure (AWS, GCP, Azure).
- The controller manager asks the cloud to provision a native load balancer with a public IP, health checks, and high availability.
- **Only works** on managed cloud clusters with a cloud provider integration. On bare metal/self-hosted it stays `Pending` (unless something like MetalLB is installed).

## ExternalName

- Maps a cluster Service name to an **external DNS record**.
- Returns a CNAME with the value in `spec.externalName`; no ClusterIP, no proxying.
- Used when an in-cluster app must reach something outside the cluster (legacy system, managed cloud database).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

## CKAD Tips

- ClusterIP is the **default** — you can omit `type`.
- NodePort range is **30000–32767**.
- LoadBalancer needs cloud integration; expect `Pending` locally.
- ExternalName has **no** ClusterIP and does **no** proxying.

## Key Takeaway

Choose the Service type by exposure need: ClusterIP for internal traffic, NodePort for quick external access, LoadBalancer for production public exposure, and ExternalName to reference external services by DNS.
