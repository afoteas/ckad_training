# Vertical Pod Autoscaling (VPA) Basics

Vertical Pod Autoscaler (VPA) automatically adjusts **CPU and memory requests/limits** for Pods based on historical and live usage. It scales **vertically** (bigger or smaller Pods), not by adding more replicas.

For horizontal scaling (replica count), see [08-HorizontalPodAutoscalingBasics](../08-HorizontalPodAutoscalingBasics/readme.md).

## Why VPA Matters

- Right-sizes workloads that were deployed with guessed resource values.
- Reduces wasted capacity from over-provisioned requests.
- Reduces OOM kills and throttling from under-provisioned requests.
- Complements HPA: VPA tunes Pod size; HPA tunes replica count.

## HPA vs VPA

| | **HPA (Horizontal)** | **VPA (Vertical)** |
|---|---|---|
| Scales | Number of **replicas** | **CPU/memory** per Pod |
| Resource changed | Pod count | `requests` and `limits` |
| Best for | Stateless apps under variable load | Right-sizing resource allocation |
| Kubernetes core? | Yes (`autoscaling/v2`) | No — separate autoscaler project |
| Typical metric | CPU/memory utilization % | Observed usage over time |

Use **HPA** when traffic spikes need more Pods. Use **VPA** when Pods need the right amount of CPU/memory.

## How VPA Works

1. **Recommender** — watches resource usage and calculates recommended requests/limits.
2. **Updater** — evicts Pods when resources need to change (depending on update mode).
3. **Admission Controller** — sets resource values on newly created Pods.

VPA does **not** scale replica count. It changes how much CPU/memory each Pod requests.

## Update Modes

The `updatePolicy.updateMode` field controls how aggressively VPA applies recommendations:

| Mode | Behavior |
|------|----------|
| `Off` | Recommendations are computed but **not applied** — useful for observation only |
| `Initial` | Sets resources only when a Pod is **first created**; no updates after |
| `Recreate` | Updates resources by **evicting and recreating** Pods |
| `Auto` | Same as `Recreate` in most installations — evicts Pods to apply new resources |

Start with `Off` or `Initial` in production to observe recommendations before enabling automatic updates.

## Core YAML Fields

- `targetRef` — the workload to manage (Deployment, StatefulSet, etc.).
- `updatePolicy.updateMode` — how recommendations are applied (`Off`, `Initial`, `Recreate`, `Auto`).
- `resourcePolicy.containerPolicies` — per-container min/max bounds and which resources to control.

## Example

See `vpa-example.yaml` for a full manifest targeting the `php-apache` Deployment from lesson 09.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: php-apache-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: "*"
      minAllowed:
        cpu: 100m
        memory: 50Mi
      maxAllowed:
        cpu: 1
        memory: 500Mi
      controlledResources: ["cpu", "memory"]
```

### Field Breakdown

| Field | Purpose |
|-------|---------|
| `targetRef` | Points VPA at the Deployment to monitor |
| `updateMode: Auto` | Apply recommendations by recreating Pods |
| `containerName: "*"` | Policy applies to all containers in the Pod |
| `minAllowed` / `maxAllowed` | Safety bounds — VPA will not go below/above these |
| `controlledResources` | Which resources VPA manages (`cpu`, `memory`) |

## Prerequisites

VPA is **not** built into core Kubernetes. You must install the VPA components separately:

```bash
# Clone the autoscaler repo and install VPA (example)
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

Verify:

```bash
kubectl get vpa
kubectl describe vpa php-apache-vpa
```

## Inspecting Recommendations

With `updateMode: Off`, VPA still computes recommendations without changing Pods:

```bash
kubectl describe vpa php-apache-vpa
```

Look for the **Recommendation** section showing suggested CPU and memory values.

## Best Practices

- Do not run VPA and HPA on the **same CPU/memory metrics** for the same workload — they can conflict.
- Use `minAllowed` and `maxAllowed` to prevent extreme recommendations.
- Start with `updateMode: Off` to review recommendations before enabling `Auto`.
- VPA works best with Deployments where Pods can be safely evicted and recreated.
- Stateful workloads need extra care — eviction may cause disruption.

## CKAD Note

HPA is the primary autoscaling topic on the CKAD exam. VPA is good to understand conceptually:

- **HPA** = more/fewer Pods
- **VPA** = bigger/smaller Pods
- VPA is a separate project, not a core Kubernetes API like HPA

## Key Takeaway

VPA right-sizes Pod resource requests and limits based on actual usage. Use it alongside — not instead of — HPA when you need both proper Pod sizing and replica scaling.
