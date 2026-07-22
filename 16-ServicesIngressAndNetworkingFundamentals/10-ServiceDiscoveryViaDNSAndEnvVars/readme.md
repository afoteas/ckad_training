# Service Discovery via DNS & Env Vars

Service discovery lets containers find and connect to their dependencies **without knowing unstable Pod IPs**. Kubernetes maps stable virtual IPs (ClusterIPs) and DNS names to the underlying Pod endpoints.

## Why It Matters

Pods are constantly created, destroyed, and rescheduled, so their IPs are temporary. Relying on Pod IPs breaks communication. Services give a dependable, stable address; discovery is how clients find that address.

## DNS-Based Discovery (preferred)

When a Service is created, the cluster DNS (**CoreDNS** or kube-dns) registers a DNS record. Each Service gets a **Fully Qualified Domain Name (FQDN)**:

```text
<service>.<namespace>.svc.cluster.local
```

- Pods in the **same namespace** can use just the short name (`<service>`).
- Cross-namespace access requires the FQDN (or at least `<service>.<namespace>`).

Cluster DNS intercepts the lookup and resolves the name to the Service's ClusterIP, which routes to the target Pods.

### Example

```bash
nslookup mysql.dev.svc.cluster.local
# → resolves to the stable ClusterIP, e.g. 10.100.23.15
```

The client then connects to that IP on the Service port.

## Environment Variable Discovery (legacy)

When a Pod is created, the kubelet injects environment variables for **Services that already exist** in that Pod's namespace:

```text
<SERVICE_NAME>_SERVICE_HOST   # ClusterIP
<SERVICE_NAME>_SERVICE_PORT   # port
```

### Example

```bash
printenv | grep MYSQL
# MYSQL_SERVICE_HOST=10.100.23.15
# MYSQL_SERVICE_PORT=3306
```

The app reads these variables to locate the Service.

## DNS vs Environment Variables

| | DNS | Environment variables |
|--|-----|-----------------------|
| Flexibility | Simple hostnames, cross-namespace via FQDN | Same-namespace only |
| Headless services | Returns multiple Pod IPs | Not supported |
| Timing | Works anytime | Only populated at **Pod creation** |
| Main use | Modern default | Backward compatibility |

**Key drawback of env vars:** if a Service is created *after* the Pod, the Pod must be **restarted** to see the new variables. Prefer DNS unless you must support legacy apps.

## Practical Considerations

- To reach a Service in another namespace, use the FQDN including the namespace: `db-service.data-namespace`.
- **CoreDNS must stay healthy** — if it fails or is overloaded, all DNS-based discovery breaks cluster-wide.
- Test both short-name and FQDN resolution in a realistic staging environment.

## CKAD Tips

- Memorize the FQDN pattern: `service.namespace.svc.cluster.local`.
- Same namespace → short name works; different namespace → include the namespace.
- Env-var discovery only reflects Services that existed **before** the Pod started.
- Debug DNS with `kubectl run tmp --rm -it --image=busybox -- nslookup <service>`.

## Key Takeaway

Use DNS for service discovery: short names within a namespace, FQDNs across namespaces. Environment variables are a legacy fallback limited to same-namespace Services that exist before the Pod is created.
