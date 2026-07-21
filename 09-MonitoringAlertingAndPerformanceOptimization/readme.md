# Monitoring, Alerting, and Performance Optimization

This module builds a complete observability stack on Kubernetes using Prometheus, Grafana, Alertmanager, and Jaeger, then extends it with distributed tracing and workload profiling.

## CKAD Exam Relevance

**Priority: Low.** Installing the full kube-prometheus-stack, building Grafana dashboards, configuring Alertmanager routes, and setting up Jaeger tracing are **not** CKAD exam tasks. The one useful takeaway is lesson 07: **`kubectl top pods/nodes`** for quick CPU/memory visibility (also requires metrics-server). If you are prioritizing study time, skip this module or read only the profiling lesson. Your probe and logging skills from module 05 cover most of what CKAD actually tests in observability.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Prometheus Operator and Kube-Prometheus Stack | Low | Prometheus Operator CRDs are not CKAD material |
| 02 | Installing Kube-Prometheus Stack via Helm | Low | Installing monitoring stacks is not tested |
| 03 | Grafana Dashboards for CKAD Metrics | Low | Grafana dashboard building is not on CKAD |
| 04 | Building a Custom Grafana Dashboard | Low | Custom dashboards are production ops, not exam ops |
| 05 | Alertmanager Routing and Notification Best Practices | Low | Alertmanager config is beyond CKAD |
| 06 | Sending Alerts to Slack via Webhook | Low | Alert routing is not CKAD scope |
| 07 | Profiling with Kubectl Top, cAdvisor, and Kube-State-Metrics | Medium | `kubectl top pods/nodes` is the main useful takeaway |
| 08 | Distributed Tracing with OpenTelemetry and Jaeger | Low | Distributed tracing is not CKAD material |
| 09 | Installing Kubernetes Dashboard and Headlamp | Low | Dashboard UIs are not tested on CKAD |

## Lesson Order

1. `01-PrometheusOperatorAndKubePrometheusStack`
2. `02-InstallingKubePrometheusStackViaHelm`
3. `03-GrafanaDashboardsForCKADMetrics`
4. `04-BuildingACustomGrafanaDashboard`
5. `05-AlertmanagerRoutingAndNotificationBestPractices`
6. `06-SendingAlertsToSlackViaWebhook`
7. `07-ProfilingWithKubectlTopCAdvisorAndKubeStateMetrics`
8. `08-DistributedTracingWithOpenTelemetryAndJaeger`
9. `09-InstallingKubernetesDashboardAndHeadlampAndExportingResources`

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
