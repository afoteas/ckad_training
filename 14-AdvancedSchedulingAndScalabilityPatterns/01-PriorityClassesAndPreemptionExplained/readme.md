# PriorityClasses and Preemption Explained

PriorityClasses let you assign numeric scheduling priorities to workloads so Kubernetes can prefer critical Pods over less important ones — and evict lower-priority Pods when resources are scarce.

For a hands-on walkthrough, see [02-CreatingPriorityClassesAndObservingPreemption](../02-CreatingPriorityClassesAndObservingPreemption/readme.md).

## Why PriorityClasses Exist

By default, Kubernetes treats every Pod equally. All Pods compete for CPU, memory, and storage with no built-in sense of importance.

In production, critical workloads (logging, payment APIs, DNS) often run alongside test or batch Pods. Under heavy load, critical Pods may fail to schedule if resources are tight.

PriorityClasses solve this by assigning **numeric priorities** to workloads:

- Higher numbers mean higher importance.
- The scheduler places high-priority Pods first.
- When necessary, lower-priority Pods are **preempted** (evicted) to make room.

This ensures system components and key microservices keep running even when the cluster is under stress.

## How PriorityClasses Work

PriorityClasses are **cluster-scoped** objects (`scheduling.k8s.io/v1`, not namespaced). Pods reference them via `spec.priorityClassName`.

| Concept | Detail |
|---------|--------|
| `value` | Integer priority — higher means more important |
| Default priority | Pods without a PriorityClass get priority `0` (unless a `globalDefault` class exists) |
| Tie-breaking | Equal priorities fall back to affinity rules and available resources |

Built-in system classes such as `system-node-critical` and `system-cluster-critical` ship with most clusters and reserve very high values for core components.

## Preemption

When the scheduler cannot place a high-priority Pod due to insufficient resources:

1. It scans the cluster for lower-priority Pods using the needed resources.
2. It evicts enough of them to free capacity.
3. It schedules the high-priority Pod.

Preemption is automatic and happens only when necessary — and only if the PriorityClass allows it (see `preemptionPolicy` below).

When choosing victims, the scheduler:

- Prefers lower-priority Pods first.
- Considers PodDisruptionBudgets and availability requirements.
- Evicts the minimum number of Pods needed to free resources.

## `value` vs `preemptionPolicy`

These are separate knobs:

| Field | Controls |
|-------|----------|
| `value` | Scheduling **priority** — higher numbers are scheduled first |
| `preemptionPolicy` | Whether the Pod can **evict** lower-priority Pods to get a node |

A high `value` does not automatically mean preemption. You choose that explicitly.

## `preemptionPolicy` Values

Only two values are valid:

| Value | Default? | Behavior |
|-------|----------|----------|
| `PreemptLowerPriority` | Yes (if omitted) | Can evict lower-priority Pods to free resources |
| `Never` | No | Higher scheduling priority, but **cannot** preempt running Pods — waits until resources free up naturally |

Use `Never` when you want a Pod scheduled ahead of lower-priority queued work without disrupting Pods already running (for example, batch or data-science jobs).

## `globalDefault`

Set `globalDefault: true` on exactly one PriorityClass to assign a default priority to Pods that omit `priorityClassName`.

| Scenario | Result for Pods without `priorityClassName` |
|----------|---------------------------------------------|
| One PriorityClass with `globalDefault: true` | That class's `value` is used |
| No `globalDefault` PriorityClass | Priority `0` |
| Multiple PriorityClasses with `globalDefault: true` | The class with the **lowest `value`** wins |

Kubernetes does not reject multiple global defaults at the API level — the priority admission controller picks the lowest `value` as a tie-break. Treat that as a safety net, not something to rely on in production.

**Example:** if `default-low` (`value: 100`, `globalDefault: true`) and `default-high` (`value: 500`, `globalDefault: true`) both exist, Pods without a class get priority **100**.

## PriorityClass Manifest

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
description: "High-priority workloads"
preemptionPolicy: PreemptLowerPriority
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `value` | Numeric priority — higher means more important |
| `globalDefault` | Default priority for Pods without `priorityClassName` — see section above |
| `preemptionPolicy` | `PreemptLowerPriority` or `Never` — see table above |
| `description` | Human-readable explanation of the class |

## Referencing a PriorityClass on a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: high-priority
  containers:
  - name: app
    image: nginx
```

The Pod inherits the priority `value` from the referenced class. You do not set the numeric priority directly on the Pod.

## Real-World Use Cases

| Scenario | How priority helps |
|----------|-------------------|
| Data processing | Critical real-time analytics preempt background ETL jobs |
| Microservices | Core billing service preempts optional feature Pods |
| Batch workloads | Production services preempt restartable batch jobs |
| System components | DNS and control-plane workloads stay schedulable under pressure |

## Risks and Trade-offs

| Risk | Detail |
|------|--------|
| Priority inflation | If every team marks their Pods as critical, nothing is truly prioritized |
| Eviction downtime | Preempted Pods can cause service disruption, especially for stateful workloads |
| Undocumented values | Teams must agree on a priority hierarchy and document values |

## Best Practices

- Use PriorityClasses **sparingly** — reserve them for truly critical workloads.
- Document priority values across teams so everyone understands the hierarchy.
- Combine with resource requests and limits for predictable scheduling.
- Reserve top priorities for control plane components, DNS, and other essential cluster services.
- Mark at most one PriorityClass as `globalDefault: true`.

## CKAD Tips

- Know the `scheduling.k8s.io/v1` `PriorityClass` kind and the `value` field.
- Pods reference priorities via `priorityClassName` — not a direct numeric field on the Pod.
- `preemptionPolicy` has only two values: `PreemptLowerPriority` (default) and `Never`.
- Only one PriorityClass should have `globalDefault: true`; if multiple do, the lowest `value` wins.
- Default priority for Pods without a class is `0` (unless a `globalDefault` class exists).

## Key Takeaway

PriorityClasses give the scheduler a clear way to differentiate nice-to-have Pods from must-run-no-matter-what Pods. Use them sparingly for critical workloads, and understand that preemption means eviction.

For a hands-on walkthrough, see [02-CreatingPriorityClassesAndObservingPreemption](../02-CreatingPriorityClassesAndObservingPreemption/readme.md).
