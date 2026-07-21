# Observability, Logging, and Probes

This module covers Kubernetes health checks, logging workflows, and metrics observability patterns used in production operations.

## CKAD Exam Relevance

**Priority: High.** Probes are among the most frequently tested CKAD topics — you must configure **liveness**, **readiness**, and **startup** probes in YAML (HTTP, TCP, or exec). `kubectl logs`, `kubectl describe`, and reading **Events** are essential troubleshooting skills used throughout the exam. Lesson 06 (metrics-server) supports HPA in module 12. Deep Prometheus/Grafana/custom metrics lessons (07–08) are production-focused and low priority for CKAD; prioritize lessons 01–05 and 06.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Kubernetes Probes | **High** | Foundational — must understand liveness vs readiness vs startup |
| 02 | Implementing Readiness and Liveness Probes | **High** | Writing probe YAML with HTTP/TCP/exec handlers is regularly tested |
| 03 | Using Startup Probes for Slow-Boot Apps | **High** | Startup probes protect slow apps; know when and how to configure them |
| 04 | Container Logging in Kubernetes | **High** | Logs go to stdout/stderr; understand how Kubernetes captures them |
| 05 | Using Kubectl Logs and Events to Debug Apps | **High** | `kubectl logs`, `kubectl get events` are used in nearly every exam task |
| 06 | Deploying and Using the Metrics Server | Medium | Required for HPA and `kubectl top`; install/verify is useful background |
| 07 | Prometheus Basics for Kubernetes | Low | Prometheus architecture is not CKAD hands-on material |
| 08 | Instrumenting Custom Application Metrics for Prometheus | Low | Custom metrics instrumentation is beyond CKAD scope |

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