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

PriorityClasses are **cluster-scoped** objects (not namespaced). Each defines an integer `value`:

| Concept | Detail |
|---------|--------|
| Priority value | Higher integer = higher scheduling priority |
| Default priority | Pods without a PriorityClass get priority `0` |
| Tie-breaking | When priorities are equal, the scheduler falls back to affinity rules and available resources |

Pods reference a PriorityClass via `priorityClassName` in their spec. The scheduler uses that value to order scheduling decisions.

## Preemption

When the scheduler cannot place a high-priority Pod due to insufficient resources:

1. It scans the cluster for lower-priority Pods using the needed resources.
2. It evicts enough of them to free capacity.
3. It schedules the high-priority Pod.

Preemption is automatic and happens only when necessary. Think of it like an airline bumping standby passengers so the flight crew can board — disruptive, but essential for system stability.

## PriorityClass YAML Example

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
| `globalDefault` | If `true`, becomes the default for Pods without an explicit class |
| `preemptionPolicy` | `PreemptLowerPriority` (default) allows eviction; `Never` disables preemption |
| `description` | Human-readable explanation of the class |

### Referencing a PriorityClass on a Pod

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

## CKAD Tips

- Know the `scheduling.k8s.io/v1` `PriorityClass` kind and the `value` field.
- Pods reference priorities via `priorityClassName`.
- `preemptionPolicy: PreemptLowerPriority` enables eviction of lower-priority Pods.
- Default priority for Pods without a class is `0`.

## Key Takeaway

PriorityClasses give the scheduler a clear way to differentiate nice-to-have Pods from must-run-no-matter-what Pods. Use them sparingly for critical workloads, and understand that preemption means eviction.
