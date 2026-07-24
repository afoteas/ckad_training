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

## How to Run (This Lesson)

### Option A: Run Local Python Instrumentation Example

From this folder:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install prometheus_client
python app.py
```

In another terminal, generate traffic and inspect metrics:

```bash
curl http://localhost:8080/
curl http://localhost:8080/metrics
```

### Option B: Run Kubernetes Metrics Demo Manifest

```bash
kubectl apply -f metrics-app-deployment.yaml
kubectl get pods -l app=metrics-app -w
kubectl get svc metrics-app-service
```

Quick in-cluster check:

```bash
kubectl run temp-tester --rm -i --restart=Never --image=busybox:stable -- wget -T 2 -O - http://metrics-app-service:9100/metrics
```

Cleanup:

```bash
kubectl delete -f metrics-app-deployment.yaml
```

## Extra Material: Prometheus Addon on Minikube

If you want a full Prometheus server in your local cluster, enable the Minikube addon:

```bash
minikube addons enable prometheus
```

If you use a non-default profile:

```bash
minikube -p mini-ckad addons enable prometheus
```

Verify Prometheus pods:

```bash
kubectl -n kube-system get pods | grep -i prometheus
```

Open the Prometheus UI:

```bash
minikube -p mini-ckad service prometheus -n kube-system
```

## CKAD Note

Custom application instrumentation — Prometheus client libraries, `/metrics` endpoints, `prometheus.io/*` annotations, and ServiceMonitors — is **beyond CKAD exam scope** and belongs to app-developer/SRE work in the real world.

- In scope instead: knowing that apps should emit signals (logs to stdout/stderr, health via probes) that Kubernetes-native tooling consumes.
- In scope: `kubectl top` (metrics-server), `kubectl logs`, and probe configuration.
- You won't write instrumentation code or configure scraping on the exam, though the `kubectl run temp-tester --rm -i --restart=Never` pattern shown here is a handy in-scope way to curl an endpoint from inside the cluster.

## Key Takeaway

Instrumenting apps with Prometheus client libraries and exposing a `/metrics` endpoint is valuable production practice but not CKAD-tested; for the exam, focus on probes, `kubectl logs`, and `kubectl top` as your observability tools.
