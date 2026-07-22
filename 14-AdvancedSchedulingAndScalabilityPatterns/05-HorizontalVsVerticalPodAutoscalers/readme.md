# Horizontal vs. Vertical Pod Autoscalers

Kubernetes provides two main autoscaling approaches: **Horizontal Pod Autoscaler (HPA)** adjusts replica count, and **Vertical Pod Autoscaler (VPA)** adjusts per-Pod CPU and memory. This lesson compares when to use each.

For HPA details, see module 12 [08-HorizontalPodAutoscalingBasics](../../12-ResourceLimitsSchedulingAndAutoscaling/08-HorizontalPodAutoscalingBasics/readme.md). For VPA hands-on practice, see [06-InstallingAndTestingTheVerticalPodAutoscaler](../06-InstallingAndTestingTheVerticalPodAutoscaler/readme.md).

## Why Autoscaling Matters

Without autoscaling, you manually update Deployments every time traffic changes. That is inefficient and error-prone — a simple typo can overprovision the cluster and waste money.

Autoscalers monitor metrics and react automatically:

- Scale up when demand rises.
- Scale down when demand drops.

## Horizontal Pod Autoscaler (HPA)

HPA scales **out or in** by adding or removing Pod replicas.

| Aspect | Detail |
|--------|--------|
| What changes | Number of Pod replicas |
| Trigger | CPU/memory utilization or custom metrics |
| Works with | Deployments, ReplicaSets, StatefulSets |
| Best for | Stateless apps with fluctuating traffic (APIs, web front ends) |

### How HPA Works

1. You define a target metric (for example 80% CPU utilization).
2. Metrics Server provides live usage data.
3. When average usage exceeds the target, HPA increases replicas.
4. When load drops, HPA reduces replicas.

Example: a web app during a sale automatically spins up more replicas — no manual intervention.

## Vertical Pod Autoscaler (VPA)

VPA scales **vertically** by adjusting CPU and memory requests/limits per Pod.

| Aspect | Detail |
|--------|--------|
| What changes | CPU/memory requests and limits per Pod |
| Trigger | Resource utilization patterns observed over time |
| Best for | Long-running, stable workloads (databases, ML jobs, background processing) |
| Side effect | May evict and recreate Pods to apply new resource values |

Think of HPA as hiring more employees; VPA as giving an existing employee more RAM.

## Side-by-Side Comparison

| | **HPA** | **VPA** |
|---|---|---|
| Scales | Pod **replica count** | Pod **resource size** |
| Direction | Horizontal (more/fewer Pods) | Vertical (bigger/smaller Pods) |
| Trigger | Real-time metrics (CPU spikes) | Historical usage patterns |
| Ideal workloads | Stateless microservices, APIs | Stateful, long-lived apps |
| Core Kubernetes? | Yes (`autoscaling/v2`) | No — separate project |

## Using Both Together

You can technically run HPA and VPA on the same workload, but they can **conflict**:

- HPA adds Pods while VPA is still adjusting resource sizes.
- This can cause instability.

In practice, most environments start with HPA and add VPA later for backend optimization. Running both on the same CPU/memory metrics is rare.

## Real-World Use Cases

| Autoscaler | Good fit | Poor fit |
|------------|----------|----------|
| HPA | E-commerce sales spikes, gaming events, APIs | Optimizing per-Pod resource allocation |
| VPA | Databases, ML pipelines, long-running batch jobs | Latency-sensitive apps that cannot tolerate restarts |

## Limitations

| Limitation | Detail |
|------------|--------|
| HPA cannot tune per-Pod resources | It only changes replica count |
| VPA causes Pod restarts | Unsuitable for latency-sensitive workloads |
| Combined use requires care | Define clear metric boundaries to avoid conflicts |

## CKAD Tips

- **HPA** = more/fewer Pods; **VPA** = bigger/smaller Pods.
- HPA uses `autoscaling/v2`; VPA uses `autoscaling.k8s.io/v1` (separate install).
- HPA is heavily tested on CKAD; VPA is conceptual.
- Pods need resource **requests** for HPA utilization-based scaling.

## Key Takeaway

Use HPA for scaling concurrency under variable load. Use VPA for right-sizing Pod resources over time. Mix them carefully — and only when the workload truly demands both.
