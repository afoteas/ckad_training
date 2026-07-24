# Grafana Dashboards for CKAD Metrics

Grafana converts Prometheus's raw time series data into visual dashboards, allowing you to instantly spot trends, anomalies, and performance issues across cluster layers.

## Dashboard Layers

| Layer | Focus |
|---|---|
| Cluster | Health and performance of the Kubernetes control plane |
| Node | CPU, memory, and disk I/O for each worker machine |
| Pod | Container restarts, CPU/memory consumption, resource limits |
| Namespace | Aggregated resource usage and network traffic per namespace |

The kube-prometheus-stack ships with hundreds of pre-built dashboards covering all standard monitoring scenarios.

## Panel Anatomy

Every panel has three core parts:

1. **Query** — PromQL expression that fetches time series data from Prometheus
2. **Visualization** — graph for time-varying metrics; gauge or single stat for instant status
3. **Thresholds** — numeric values that trigger color changes (e.g., yellow at 70%, red at 90%)

## Example Panel (JSON)

```json
{
  "title": "Pod CPU Usage",
  "type": "graph",
  "targets": [
    {
      "expr": "rate(container_cpu_usage_seconds_total{pod='myapp'}[5m])"
    }
  ]
}
```

`rate(...[5m])` calculates the per-second average CPU increase over 5 minutes — the most meaningful way to monitor container CPU.

## Key PromQL Queries to Know

```promql
# CPU utilization rate for a container
rate(container_cpu_usage_seconds_total{container="myapp"}[5m])

# Memory usage
container_memory_usage_bytes{pod="myapp"}

# Container restart count
kube_pod_container_status_restarts_total{namespace="default"}
```

## Best Practices

- start with pre-built dashboards from kube-prometheus-stack before building custom ones
- master PromQL for CPU, memory, and container restart counts
- keep custom dashboards simple: one or two critical metrics per panel
- export and share the same core dashboards across dev, staging, and production for a consistent source of truth
- use alerting in production but focus on diagnosis and repair during exam scenarios

## CKAD Note

Grafana dashboards and PromQL are real-world observability skills but are **not** tested on CKAD — despite the chapter name, you won't write `rate(container_cpu_usage_seconds_total[5m])` on the exam.

- For exam metrics, use `kubectl top pod` / `kubectl top node` (see `07-...`) to get the same CPU/memory snapshot Grafana visualizes.
- Diagnose with `kubectl describe`, `kubectl logs`, and `kubectl get events` rather than dashboards; treat PromQL as background knowledge only.

## Key Takeaway

Grafana turns Prometheus time series into visual dashboards layered from cluster down to pod — invaluable in production, but for CKAD the equivalent insight comes from `kubectl top` and core inspection commands, not PromQL panels.
