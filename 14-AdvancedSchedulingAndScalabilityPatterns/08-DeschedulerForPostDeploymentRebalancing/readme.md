# Descheduler for Post-Deployment Rebalancing

The Kubernetes scheduler places Pods once at creation time and rarely revisits that decision. Over time, clusters become imbalanced. The descheduler acts as a cluster housekeeper — periodically evicting Pods that could be better placed.

For a hands-on Helm deployment, see [09-RunningDeschedulerAsACronJob](../09-RunningDeschedulerAsACronJob/readme.md).

## Example Files

- `descheduler-policy.yaml` — reference `LowNodeUtilization` policy structure

## Why Descheduler Exists

After initial scheduling, cluster conditions change:

- Some nodes become overloaded while others sit nearly empty.
- New nodes join but existing Pods stay on old nodes.
- Affinity or topology rules are updated, but existing Pods violate them.

The scheduler does not automatically fix these imbalances. The descheduler does.

| Component | When it acts | What it does |
|-----------|--------------|--------------|
| **Scheduler** | Pod creation time | Places new Pods on nodes |
| **Descheduler** | Periodic runs | Evicts misplaced Pods so the scheduler can reschedule them |

The descheduler does not create or delete Pods — it only evicts them to better positions.

## Common Strategies

Enable strategies based on what you need to fix:

| Strategy | Purpose |
|----------|---------|
| `RemoveDuplicates` | Evict duplicate Pods stacked on the same node |
| `LowNodeUtilization` | Rebalance Pods from over-utilized to under-utilized nodes |
| `RemovePodsViolatingInterPodAntiAffinity` | Enforce inter-Pod anti-affinity rules |
| `RemovePodsViolatingNodeAffinity` | Enforce node affinity rules |
| `RemovePodsViolatingTopologySpreadConstraint` | Enforce topology spread rules |
| `PodLifeTime` | Evict Pods running longer than a configured age |

You can mix and match strategies in a single policy.

## LowNodeUtilization Example

See `descheduler-policy.yaml` for the full policy. In production this policy is typically embedded in a Helm values file (see lesson 09).

```bash
cat descheduler-policy.yaml
```

### How Thresholds Work

| Threshold type | Meaning |
|----------------|---------|
| `thresholds` (20%) | Nodes below 20% CPU/memory/Pods are **underutilized** |
| `targetThresholds` (50%) | Goal is to keep nodes around 50% utilization after rebalancing |

The descheduler evicts Pods from overutilized nodes so the scheduler can place them on underutilized ones.

## Typical Use Cases

| Scenario | How descheduler helps |
|----------|----------------------|
| After Cluster Autoscaler scale-up | Redistribute workloads across newly added nodes |
| Policy enforcement | Align existing Pods with updated affinity or topology rules |
| Cost optimization | Consolidate workloads before scaling down idle nodes |
| Dev/CI clusters | Evict long-running or obsolete Pods regularly |

## Important Caveats

| Caveat | Detail |
|--------|--------|
| Not a scheduler replacement | Descheduler only makes corrective adjustments after the fact |
| Evictions cause disruption | Use Pod Disruption Budgets to protect availability |
| Tune thresholds carefully | Aggressive settings move Pods too frequently, adding latency |
| Requires monitoring | Confirm it improves balance rather than creating churn |
| Start in staging | Test descheduler settings in dev/staging before production |

## Best Practices

- Use Pod Disruption Budgets for workloads that must stay available during evictions.
- Start with conservative thresholds and monitor the impact.
- Run periodically (for example nightly) rather than continuously.
- Combine with Cluster Autoscaler for cost-efficient node consolidation.

## CKAD Note

Descheduler is not a CKAD exam topic. Know conceptually:

- Scheduler places Pods once; descheduler rebalances them later.
- Descheduler evicts Pods — it does not create or delete them.
- Common strategy: `LowNodeUtilization` for balancing overloaded and idle nodes.

## Key Takeaway

The descheduler keeps clusters balanced over time by evicting Pods that violate utilization or placement policies. Use it as corrective maintenance — not as a replacement for proper initial scheduling.
