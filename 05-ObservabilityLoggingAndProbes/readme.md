# Observability, Logging, and Probes

This module covers Kubernetes health checks, logging workflows, and metrics observability patterns used in production operations.

## Lesson Order

1. `01-KubernetesProbes`
2. `02-ImplementingReadinessAndLivenessProbes`
3. `03-UsingStartupProbesForSlowBootApps`
4. `04-ContainerLoggingInKubernetes`
5. `05-UsingKubectlLogsAndEventsToDebugApps`
6. `06-DeployingAndUsingTheMetricsServer`
7. `07-PrometheusBasicsForKubernetes`
8. `08-InstrumentingCustomApplicationMetricsForPrometheus`

## What You Learn

- how liveness, readiness, and startup probes drive self-healing and traffic safety
- how Kubernetes logging works from stdout/stderr to centralized collectors
- practical pod troubleshooting with `kubectl get`, `describe`, `logs`, and `events`
- how to install and verify metrics-server for CPU and memory visibility
- Prometheus architecture, exporters, and PromQL basics
- how to expose custom application metrics for Prometheus scraping
