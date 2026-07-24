# Prometheus Basics for Kubernetes

Prometheus is the de facto metrics system for Kubernetes observability.

## Core Components

- Prometheus server (scrape + TSDB)
- service discovery (pods/services/endpoints/nodes)
- exporters (node-exporter, kube-state-metrics, cAdvisor exposure)
- Alertmanager
- PromQL query engine

## Pull Model

Prometheus scrapes HTTP metrics endpoints at configured intervals.

## Exporters in Kubernetes

1. `node-exporter`: collects node-level metrics such as CPU, memory, filesystem, and network.
2. `cAdvisor`: provides container-level performance metrics (CPU, memory, I/O, filesystem usage).
3. `kube-state-metrics`: exposes Kubernetes object state metrics (for example deployments, pods, replicas, jobs).

## PromQL Examples

```promql
rate(container_cpu_usage_seconds_total{namespace="default"}[5m])
container_memory_usage_bytes{namespace="default"}
count by (deployment) (kube_pod_info{namespace="default"})
```

## Operational Challenges

- high cardinality label explosion
- retention and long-term storage planning
- alert noise reduction
- scaling and high availability architecture

## CKAD Note

Prometheus internals, PromQL, exporters, and Alertmanager are **beyond CKAD exam scope** — treat this chapter as real-world observability background, not test material.

- Examinable in-scope alternative: `kubectl top nodes/pods` via the metrics-server for resource usage.
- Also in scope: reading `kubectl logs` and `kubectl describe`/`kubectl get events` for troubleshooting.
- You will not be asked to write PromQL, deploy Prometheus, or configure exporters/ServiceMonitors on the exam.

## Key Takeaway

Prometheus is the industry-standard pull-based metrics stack for Kubernetes, but for the CKAD you only need to recognize it conceptually — resource-usage tasks are handled with metrics-server and `kubectl top`.
