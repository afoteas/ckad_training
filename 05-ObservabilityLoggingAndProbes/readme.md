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

## Objectives 
- describe the liveness, readiness, and startup probes in Kubernetes, including when to use each
- implement readiness and liveness probes with custom thresholds
- use startup probes to delay other checks during application bootstrapping
- identify where logs are stored and how to collect them
- use `kubectl logs` and `events` to troubleshoot containers
- deploy the `metrics-server` and validate CPU/memory visibility
- outline how to scrape metrics and the basics of Prometheus queries (`PromQL`)
- instrument app code to export custom metrics to Prometheus