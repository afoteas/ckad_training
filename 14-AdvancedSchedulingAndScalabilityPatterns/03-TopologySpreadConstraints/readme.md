# Topology Spread Constraints

Topology spread constraints control **where** Pods are placed across failure domains — zones, racks, or hostnames — to reduce the risk of a single failure taking down an entire service.

For a hands-on zone distribution demo, see [04-ZoneAwareDistributionWithSpreadConstraints](../04-ZoneAwareDistributionWithSpreadConstraints/readme.md).

## Example Files

- `deployment-with-spread.yaml` — Deployment with zone-based topology spread constraints

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

## Example Deployment

Label nodes with zone labels first (required for spread across zones):

```bash
kubectl label node <node-1> topology.kubernetes.io/zone=us-east-1a
kubectl label node <node-2> topology.kubernetes.io/zone=us-east-1b
kubectl label node <node-3> topology.kubernetes.io/zone=us-east-1c
kubectl apply -f deployment-with-spread.yaml
kubectl get pods -l app=web -o wide
```

See `deployment-with-spread.yaml` for the full manifest. This ensures replicas are evenly distributed across availability zones. If spread cannot be met, Pods remain `Pending` rather than stacking on one zone.

## What `topologyKey` Is

`topologyKey` is **the name of a label that exists on your Nodes**. The scheduler groups nodes by the *value* of that label and treats each distinct value as one "domain" to balance Pods across.

So `topologyKey` does not take a fixed enum — it accepts **any node label key**. The value of that label on each node is what defines the domain boundaries.

```text
topologyKey: topology.kubernetes.io/zone   # label KEY on the node
              │
              └─ each distinct label VALUE (us-east-1a, us-east-1b, ...) is one domain
```

### Well-Known Topology Labels

Kubernetes reserves a `topology.kubernetes.io/` label family for location. These are the values you will normally use as a `topologyKey`:

| Label key | Domain granularity | Example value |
|-----------|-------------------|---------------|
| `topology.kubernetes.io/region` | Cloud region (coarsest) | `us-east-1` |
| `topology.kubernetes.io/zone` | Availability zone within a region | `us-east-1a` |
| `kubernetes.io/hostname` | A single node (finest) | `minikube-m02` |

A region contains multiple zones; each zone is an isolated data center. Spreading across `zone` protects against a data-center outage; spreading across `hostname` protects against a single node failure.

### Custom Topology Keys

You are not limited to the well-known labels. Any label you put on nodes can be a `topologyKey` — useful for physical layout the cloud doesn't model:

```yaml
topologyKey: rack          # e.g. rack=r1, rack=r2
topologyKey: failure-domain # any custom scheme you define
```

The only requirement: the nodes you want to spread across must **carry that label**. Nodes missing the `topologyKey` label are excluded from spreading for that constraint.

## Assigning Topology Labels to Nodes

### On Cloud Providers (automatic)

Managed clusters (EKS, GKE, AKS) run a **cloud controller manager** that reads instance metadata and applies `topology.kubernetes.io/region` and `topology.kubernetes.io/zone` to every node automatically. `kubernetes.io/hostname` is set by the kubelet on every node, everywhere. You usually don't label anything yourself.

### On Bare Metal / Minikube (manual)

There is no cloud metadata, so you assign the labels with `kubectl label`:

```bash
# Syntax: kubectl label node <node-name> <key>=<value>
kubectl label node minikube      topology.kubernetes.io/zone=us-east-1a
kubectl label node minikube-m02  topology.kubernetes.io/zone=us-east-1b
kubectl label node minikube-m03  topology.kubernetes.io/zone=us-east-1c
```

Custom keys work the same way:

```bash
kubectl label node minikube-m02 rack=r1
```

### Verifying and Managing Labels

```bash
# Show a specific label as a column for all nodes
kubectl get nodes -L topology.kubernetes.io/zone

# Show every label on one node
kubectl get node minikube --show-labels

# Overwrite an existing label (must add --overwrite)
kubectl label node minikube-m02 topology.kubernetes.io/zone=us-east-1c --overwrite

# Remove a label (trailing minus)
kubectl label node minikube-m02 topology.kubernetes.io/zone-
```

If a node lacks the `topologyKey` label, it won't participate in that spread constraint — a common reason Pods bunch up or stay `Pending` unexpectedly.

## Advantages Over `nodeSelector` and Affinity

`nodeSelector`, node affinity, and pod anti-affinity can influence placement too — but none of them express **"spread evenly"** as cleanly as topology spread constraints.

| Approach | What it does | Limitation for even distribution |
|----------|--------------|----------------------------------|
| `nodeSelector` | Pins Pods to nodes with a matching label | Binary match only — cannot balance counts across domains; all Pods can still land on one matching node |
| Node affinity | Attracts/repels Pods to/from nodes by label rules | Controls *which* nodes are eligible, not *how evenly* Pods are spread among them |
| Pod anti-affinity | Keeps Pods of a label apart | Effectively "at most one per domain" — coarse, and gets expensive at scale (evaluated pairwise across all Pods) |
| Topology spread | Balances Pod counts across domains within `maxSkew` | Purpose-built for even distribution |

Key advantages of topology spread constraints:

- **Quantitative balance.** `maxSkew` lets you say "domains may differ by at most N Pods" — anti-affinity can only say "keep them apart," which usually means one-per-domain and no finer control.
- **Scales past the number of domains.** With anti-affinity (one Pod per zone), a 4th replica across 3 zones has nowhere to go. Spread constraints happily place `2-1-1`, then `2-2-1`, and so on.
- **Tunable strictness.** `whenUnsatisfiable: ScheduleAnyway` degrades gracefully under pressure; `DoNotSchedule` enforces hard balance. Anti-affinity `required` rules are all-or-nothing.
- **Cheaper at scale.** Spread is evaluated per topology domain, while pod anti-affinity is evaluated pairwise across matching Pods and becomes costly in large clusters.
- **Composable.** You can still combine spread with `nodeSelector`/affinity — use affinity to pick *eligible* nodes, and spread to *balance* across them.

Rule of thumb: use `nodeSelector`/affinity to decide **where Pods may go**, and topology spread constraints to decide **how evenly they land there**.

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
