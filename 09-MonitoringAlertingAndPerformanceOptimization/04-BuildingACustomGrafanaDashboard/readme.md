# Building a Custom Grafana Dashboard

This demo creates a new Grafana dashboard from scratch and adds panels to visualize application health metrics (latency, error rate) using Prometheus as the data source.

## Prerequisites

Prometheus and Grafana running in the cluster (see `02-InstallingKubePrometheusStackViaHelm`).

## Deploy the Sample Application

The sample app (`sample-app-deployment.yaml`) runs `prom/client_golang-example` and exposes Prometheus metrics on port 8080. The critical annotations that enable scraping:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
```

Without these annotations Prometheus will not discover the pod.

```bash
kubectl apply -f sample-app-deployment.yaml

# Verify pods are running
kubectl get pods -l app=demo-app
```

Allow a minute for Prometheus to discover and begin scraping the new target.

## Create a Dashboard in Grafana

1. In the left nav, click **Dashboards**
2. Click the **+** icon (top right) → **New Dashboard**
3. Click **Add visualization**
4. Select **Prometheus** as the data source

## Add a Panel

In the **Metric** field, search for and select your metric, for example:

```
http_request_duration_seconds_sum
```

Set the panel title (e.g. `HTTP Request Duration (seconds)`) and click **Back to Dashboard**.

## Save

Click **Save dashboard** (top right), provide a name, and click **Save**.

## Adjust Time Range

Use the time picker (top right) to select **Last 30 minutes** or **Last 15 minutes** to see recent data from the newly scraped application.

## Notes

- it can take 1–2 minutes after deployment for Prometheus to start scraping a new target
- the panel will show a flat or empty chart until scrape data is available
- panel types available: graph (time series), gauge, single stat, heatmap — choose based on what the metric represents
