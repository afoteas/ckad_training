# Headless Services and StatefulSets

Most Services provide a single load-balanced IP. A **headless Service** does the opposite: it lets clients discover and connect **directly to individual Pod endpoints**. This is essential for stateful, clustered applications where individual member identity matters.

## Example Files

| File | Purpose |
|------|---------|
| `headless-service.yaml` | Headless Service (`clusterIP: None`) for `app: mysql` |
| `mysql-statefulset.yaml` | 3-replica StatefulSet referencing the headless Service |

## What Makes a Service Headless

Set `clusterIP: None`. This tells Kubernetes **not** to allocate a single load-balanced IP:

```yaml
spec:
  clusterIP: None
  selector:
    app: mysql
```

The only difference from a normal ClusterIP Service is that one field.

## How DNS Changes

- A normal Service resolves to **one** ClusterIP.
- A headless Service resolves to a **list of A records** — one IP per ready Pod matching the selector.
- Because there is no ClusterIP, **kube-proxy is bypassed** and no internal load balancing happens.

The **client** decides which Pod IP to connect to — load balancing and connection logic move to the application layer.

## Pairing with a StatefulSet

A headless Service is the required partner for a StatefulSet, which provides stable Pod identity:

1. A StatefulSet creates Pods with **ordered, persistent names** — `mysql-0`, `mysql-1`, `mysql-2` (0-based indexing).
2. The StatefulSet references the headless Service via `serviceName: "mysql"`.
3. Each Pod gets its own predictable DNS entry:

```text
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

So the three Pods become `mysql-0.mysql`, `mysql-1.mysql`, `mysql-2.mysql`, and the whole set can be discovered via `mysql.default.svc.cluster.local`.

## Real-World Use Cases

- **Databases** (MySQL, PostgreSQL) — one Pod is the primary/leader (Pod 0); clients must address it by name.
- **Message queues** (Kafka) — partition-aware clients connect to specific brokers.
- **Caches** (Redis, Memcached) — consistent hashing requires clients to know all node addresses.
- **Leader election** (ZooKeeper, etcd) — all Pods need stable identities to communicate.

## CKAD Tips

- Headless = `clusterIP: None` (not a `type`).
- StatefulSet Pod DNS: `pod-name.service-name.namespace.svc.cluster.local`.
- StatefulSet indexing is **0-based** and ordered.
- `serviceName` in the StatefulSet must match the headless Service name.

## Key Takeaway

Set `clusterIP: None` to make a Service headless so DNS returns individual Pod IPs. Combined with a StatefulSet's stable naming, this gives each Pod a durable network identity for clustered, stateful workloads.
