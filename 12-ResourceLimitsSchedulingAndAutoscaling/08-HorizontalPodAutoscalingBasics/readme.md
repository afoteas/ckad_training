# Horizontal Pod Autoscaling (HPA) Basics

Horizontal Pod Autoscaler (HPA) automatically adjusts replica count based on load metrics.

## Why HPA Matters

- Handles traffic spikes without manual intervention.
- Reduces over-provisioning during low demand.
- Improves availability and cost efficiency.

## HPA Feedback Loop

1. Define target utilization (for example CPU 50%).
2. Metrics pipeline provides live resource usage.
3. HPA controller compares actual usage against target.
4. Controller scales replicas up or down.

## Core YAML Fields

- `scaleTargetRef`: workload to scale.
- `minReplicas`: lower safety bound.
- `maxReplicas`: upper cost and capacity bound.
- `metrics`: signal used for scaling (CPU, memory, custom, external).

## Metric Types

- CPU utilization (most common).
- Memory utilization.
- Custom metrics (for example requests per second via adapter).
- External metrics (for example queue length outside cluster).

## Prerequisites

- Metrics Server installed for CPU and memory based scaling.
- Target workload has sensible CPU and memory requests.

## Best Practices

- Choose realistic min/max bounds.
- Avoid aggressive scaling thrash by understanding stabilization behavior.
- Prefer stateless applications for straightforward horizontal scaling.

## Key Takeaway

HPA turns reactive manual scaling into an automated control loop driven by cluster metrics.
