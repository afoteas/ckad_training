# Instrumenting Custom Application Metrics for Prometheus

This lesson shows how to expose application-level metrics so Prometheus can scrape them.

## Instrumentation Workflow

1. add Prometheus client library to app code
2. define metric(s) such as counters and gauges
3. increment/update metrics in request handlers
4. expose `/metrics` endpoint
5. annotate deployment or configure ServiceMonitor for scraping

## Python Example Pattern

- define counter: `http_requests_total`
- increment on each request
- run metrics HTTP endpoint

## Kubernetes Exposure Pattern

Use pod annotations or monitoring operator resources so Prometheus discovers the endpoint.

Common annotations:

- `prometheus.io/scrape: "true"`
- `prometheus.io/port: "8080"`
- `prometheus.io/path: "/metrics"`

## Verify Endpoint from Cluster

```bash
kubectl get pod -l app=metrics-app -o wide
kubectl run temp-tester --rm -i --restart=Never --image=busybox:stable -- wget -T 2 -O - http://<pod-ip>:8080/metrics
```

If output shows metric lines, instrumentation is working.
