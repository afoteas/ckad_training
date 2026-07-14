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
