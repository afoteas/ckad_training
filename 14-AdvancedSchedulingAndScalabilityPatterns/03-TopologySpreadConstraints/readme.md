# Topology Spread Constraints

Topology spread constraints control **where** Pods are placed across failure domains — zones, racks, or hostnames — to reduce the risk of a single failure taking down an entire service.

For a hands-on zone distribution demo, see [04-ZoneAwareDistributionWithSpreadConstraints](../04-ZoneAwareDistributionWithSpreadConstraints/readme.md).

## Why Pod Distribution Matters

By default, the Kubernetes scheduler finds any node with enough resources. It does not care whether all replicas of a service land on the same node, zone, or rack.

If multiple replicas of the same service end up on one node, that node becomes a single point of failure. One machine failure can take the entire service offline.

Topology spread constraints tell Kubernetes to spread Pods across failure domains, building resilience and high availability into scheduling logic without changing what Pods you run — only where they run.

## Key Fields

Define spread rules under `spec.topologySpreadConstraints`:

| Field | Purpose |
|-------|---------|
| `maxSkew` | Maximum allowed difference in Pod count between any two topology domains |
| `topologyKey` | Node label that defines the domain (zone, hostname, rack) |
| `whenUnsatisfiable` | What to do if the rule cannot be met: `DoNotSchedule` or `ScheduleAnyway` |
| `labelSelector` | Which Pods the rule applies to (usually matches workload labels) |

### `maxSkew` Explained

`maxSkew: 1` means the difference in Pod count between any two domains cannot exceed 1.

With 3 zones and 6 replicas, valid distributions include `2-2-2` or `3-2-2` (skew of 1) but not `4-1-1` (skew of 3).

### `whenUnsatisfiable`

| Value | Behavior |
|-------|----------|
| `DoNotSchedule` | Hard constraint — Pod stays `Pending` if spread cannot be satisfied |
| `ScheduleAnyway` | Soft constraint — schedule anyway with best-effort spread |

## Example YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web
      containers:
      - name: nginx
        image: nginx
```

This ensures replicas are evenly distributed across availability zones. If spread cannot be met, Pods remain `Pending` rather than stacking on one zone.

## Common Topology Keys

| `topologyKey` | Domain |
|---------------|--------|
| `topology.kubernetes.io/zone` | Availability zone |
| `topology.kubernetes.io/region` | Cloud region |
| `kubernetes.io/hostname` | Individual node |

Cloud providers typically label nodes automatically. In local clusters, you label nodes manually.

## When to Use Spread Constraints

| Scenario | Benefit |
|----------|---------|
| Multi-zone clusters | One zone outage does not take down all replicas |
| Critical services (auth, APIs, logging) | Even distribution reduces cascading failures |
| Regulatory compliance | Enforce physical or logical separation of workloads |
| Load balancing | Prevent hotspots on overloaded nodes or racks |

## Trade-offs

| Consideration | Detail |
|---------------|--------|
| Scheduling failures | Without enough nodes or labels, `DoNotSchedule` can leave Pods `Pending` |
| Interaction with affinity | Spread constraints must align with node affinity/anti-affinity rules |
| Scheduling overhead | Strict rules add scheduling complexity in large clusters |
| Node labeling | Nodes must have correct topology labels for spread to work |

## Best Practices

- Use spread constraints where resilience genuinely matters — not on every workload.
- Ensure nodes are labeled with correct topology keys (`zone`, `hostname`, etc.).
- Start with `maxSkew: 1` for the strictest balance; increase for more flexibility.
- Use `DoNotSchedule` for critical apps; `ScheduleAnyway` for less critical workloads.
- Combine with resource requests for predictable scheduling.

## CKAD Tips

- Know all four fields: `maxSkew`, `topologyKey`, `whenUnsatisfiable`, `labelSelector`.
- `DoNotSchedule` = hard constraint; `ScheduleAnyway` = soft constraint.
- `topology.kubernetes.io/zone` is the most common `topologyKey` on the exam.
- Spread constraints live in the Pod template spec, not at the Deployment metadata level.

## Key Takeaway

Topology spread constraints proactively distribute Pods across failure domains. Use them where resilience matters, but balance strict guarantees with operational simplicity and correct node labeling.
