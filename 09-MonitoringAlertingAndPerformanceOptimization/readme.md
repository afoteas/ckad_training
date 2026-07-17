# Monitoring, Alerting, and Performance Optimization

This module builds a complete observability stack on Kubernetes using Prometheus, Alertmanager, and Grafana, then extends it with distributed tracing and workload profiling.

## Lesson Order

1. `01-PrometheusOperatorAndKubePrometheusStack`
2. `02-InstallingKubePrometheusStackViaHelm`
3. `03-GrafanaDashboardsForCKADMetrics`
4. `04-BuildingACustomGrafanaDashboard`
5. `05-AlertmanagerRoutingAndNotificationBestPractices`
6. `06-SendingAlertsToSlackViaWebhook`
7. `07-ProfilingWithKubectlTopCAdvisorAndKubeStateMetrics`
8. `08-DistributedTracingWithOpenTelemetryAndJaeger`

## What You Learn

- how the Prometheus Operator manages the monitoring stack lifecycle via CRDs
- how to install the full kube-prometheus-stack with Helm and verify it is working
- how Grafana dashboards are structured and which PromQL queries matter most
- how to build a custom Grafana dashboard from scratch
- how Alertmanager routes alerts to the right teams using receivers, routes, inhibition, and silences
- how to configure a Slack webhook receiver and validate alert delivery end to end
- how to profile workloads using `kubectl top`, cAdvisor, and kube-state-metrics
- how distributed tracing works with OpenTelemetry and Jaeger

## Objectives

- install and verify kube-prometheus-stack on a cluster
- create ServiceMonitor and PrometheusRule CRDs for a sample application
- build Grafana panels using PromQL for CPU, memory, and container restarts
- configure Alertmanager routing with severity-based rules
- connect Alertmanager to an external notification channel via webhook
- use the three-step profiling workflow (kubectl top → cAdvisor → kube-state-metrics) to diagnose resource issues
- explain the role of traces, spans, and trace IDs in a microservice architecture
