# Horizontal Pod Autoscaling (HPA) Basics

Horizontal Pod Autoscaler (HPA) automatically adjusts **replica count** based on load metrics. When demand rises, HPA adds Pods; when demand falls, it removes them.

For a hands-on walkthrough, see [09-ImplementingHPAInALiveApp](../09-ImplementingHPAInALiveApp/readme.md).

## Why HPA Matters

- Handles traffic spikes without manual intervention.
- Reduces over-provisioning during low demand.
- Improves availability and cost efficiency.

## HPA Feedback Loop

1. You define a target metric (for example CPU at 50%).
2. Metrics Server (or a custom metrics adapter) provides live usage data.
3. HPA compares actual usage against the target.
4. HPA updates the workload's `replicas` field up or down.

```text
Load increases → CPU above target → HPA scales up replicas
Load decreases → CPU below target → HPA scales down replicas
```

## API Version

Use `autoscaling/v2` for CKAD and modern clusters. It supports multiple metric types and richer scaling behavior than `autoscaling/v1`.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
```

## Core YAML Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `scaleTargetRef` | Yes | The workload HPA scales (Deployment, StatefulSet, etc.) |
| `minReplicas` | No (default: 1) | Minimum number of replicas |
| `maxReplicas` | Yes | Maximum number of replicas |
| `metrics` | No (default: CPU 80%) | Metric(s) used to decide scaling |
| `behavior` | No | Fine-tune scale-up/scale-down speed and policies |

### `scaleTargetRef` — Supported Workload Types

| Kind | Common use |
|------|------------|
| `Deployment` | Most common HPA target |
| `StatefulSet` | Stateful apps that can scale horizontally |
| `ReplicaSet` | Lower-level controller (less common to target directly) |

Example:

```yaml
scaleTargetRef:
  apiVersion: apps/v1
  kind: Deployment
  name: php-apache
```

## Metric Types

HPA v2 supports four metric `type` values:

| Type | Source | CKAD relevance | Example |
|------|--------|----------------|---------|
| `Resource` | Built-in Pod resources | **High** — most common on exam | CPU or memory utilization |
| `Pods` | Per-Pod custom metric | Low | Average requests per second across Pods |
| `Object` | Metric for a specific object | Low | Ingress requests per second |
| `External` | Cluster-external metric | Low | Queue length from a message broker |

For CKAD, focus on **`Resource`** metrics (CPU and memory).

## Resource Metric Options

When `type: Resource`, set `resource.name` to `cpu` or `memory`.

| `resource.name` | `target.type` | `target` field | Meaning |
|-----------------|---------------|----------------|---------|
| `cpu` | `Utilization` | `averageUtilization` | Target average CPU as a **percentage** of each Pod's CPU **request** |
| `memory` | `Utilization` | `averageUtilization` | Target average memory as a **percentage** of each Pod's memory **request** |
| `cpu` | `AverageValue` | `averageValue` | Target average CPU as an absolute value (for example `200m`) |
| `memory` | `AverageValue` | `averageValue` | Target average memory as an absolute value (for example `256Mi`) |

**Important:** For `Utilization` targets, Pods **must** have `resources.requests` set. HPA calculates utilization as:

```text
actual usage / requested amount × 100
```

Without requests, HPA cannot compute CPU/memory utilization and will not scale.

## Examples

### Example 1: CPU Utilization (most common)

Scale a Deployment when average CPU across Pods exceeds 50% of requested CPU:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

The target Deployment must define CPU requests:

```yaml
resources:
  requests:
    cpu: 200m
```

### Example 2: Memory Utilization

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75
```

### Example 3: CPU with Absolute Average Value

Scale based on average CPU usage of `300m` per Pod instead of a percentage:

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: AverageValue
      averageValue: 300m
```

### Example 4: Multiple Metrics

HPA v2 can scale based on more than one metric. The controller calculates a replica count for each metric and uses the **highest** result:

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 50
- type: Resource
  resource:
    name: memory
    target:
      type: Utilization
      averageUtilization: 80
```

## Prerequisites

| Requirement | Why |
|-------------|-----|
| **Metrics Server** installed | Required for CPU and memory `Resource` metrics |
| **CPU/memory requests** on containers | Required for `Utilization`-based scaling |
| **Target workload running** | HPA needs Pods to measure before scaling |

Verify Metrics Server:

```bash
kubectl get apiservice v1beta1.metrics.k8s.io
kubectl top pods
kubectl top nodes
```

## Useful Commands

```bash
# Create and inspect HPA
kubectl apply -f hpa-config.yaml
kubectl get hpa
kubectl describe hpa php-apache-hpa

# Watch scaling in real time
kubectl get hpa -w
kubectl get pods -w

# Check current resource usage
kubectl top pods
```

`kubectl describe hpa` shows **Metrics**, **Conditions**, and the scaling **Events** — useful for troubleshooting.

## What HPA Does Not Do

| HPA does | HPA does not |
|----------|--------------|
| Change **replica count** | Change CPU/memory **requests or limits** (that is VPA) |
| React to live metrics | Replace the need for resource requests |
| Scale Deployments/StatefulSets | Scale a single Pod vertically |

## Best Practices

- Set realistic `minReplicas` and `maxReplicas` bounds.
- Always define CPU requests on workloads scaled by CPU utilization.
- Prefer stateless applications for straightforward horizontal scaling.
- Use `kubectl describe hpa` when scaling does not behave as expected.
- Avoid running HPA and VPA on the same CPU/memory metrics for the same workload.

## CKAD Tips

- Know the `autoscaling/v2` HPA structure: `scaleTargetRef`, `minReplicas`, `maxReplicas`, `metrics`.
- Most exam scenarios use **CPU utilization** with `type: Resource`.
- Remember: **no requests = no utilization-based scaling**.
- `maxReplicas` is required; `minReplicas` defaults to 1.
- HPA modifies the workload's `replicas` field — you do not manually set replicas on the Deployment after HPA takes over.

## Key Takeaway

HPA turns reactive manual scaling into an automated control loop driven by cluster metrics. For CKAD, master CPU-based `Resource` metrics with `averageUtilization` and ensure your target Pods have resource requests defined.
