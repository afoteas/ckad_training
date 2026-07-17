# Prometheus Operator and kube-prometheus-stack

The Prometheus Operator automates the entire lifecycle of the Prometheus monitoring stack, eliminating the need to manually write Kubernetes configuration files for each component and wire them together.

## Core Components

- **Prometheus** — scrapes metrics from targets, stores time series data locally, and exposes PromQL for querying
- **Alertmanager** — receives alerts from Prometheus, groups and deduplicates them, and routes them to the correct receiver
- **Grafana** — visualization layer that connects to Prometheus and renders dynamic dashboards
- **Exporters** — small programs that collect metrics from a specific system (database, nginx, OS) and expose them in a format Prometheus can scrape

## Custom Resource Definitions (CRDs)

The operator extends the Kubernetes API with new native objects:

| CRD | Purpose |
|---|---|
| `ServiceMonitor` | Tells Prometheus where to scrape metrics by targeting a Service via label selectors |
| `PodMonitor` | Like ServiceMonitor but targets individual Pods directly |
| `PrometheusRule` | Defines alerting rules using PromQL expressions |
| `AlertmanagerConfig` | Configures receivers and routing trees without editing native Alertmanager config files |

## ServiceMonitor Example

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: web-monitor
spec:
  selector:
    matchLabels:
      app: web
  endpoints:
    - port: http
```

The `matchLabels` block finds any Service with `app: web`. The `endpoints` block tells Prometheus to scrape the port named `http` on those services.

## Why the Operator

Without the operator, upgrades require careful planning, manual configuration changes, and precise execution. With it:

- scaling is often a single number change in a CRD definition
- upgrades are handled semi-automatically
- all configuration is declarative YAML stored in Git
- the operator adapts automatically as the cluster grows or shrinks

## Considerations

- CRDs are cluster-scoped; their addition is a security and governance decision for cluster administrators
- Alertmanager and Grafana endpoints expose sensitive information — secure them with Ingress, NetworkPolicies, or RBAC
- the operator simplifies deployment but does not automatically secure monitoring data and access
