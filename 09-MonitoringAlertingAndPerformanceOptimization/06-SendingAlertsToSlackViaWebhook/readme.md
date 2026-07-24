# Sending Alerts to Slack via Webhook

This demo configures Prometheus Alertmanager to route high-priority alerts to a Slack channel via a webhook, then deploys a CPU stress workload to trigger and validate the alert pipeline.

## Files Required

| File | Purpose |
|---|---|
| `alertmanager-config.yml` | Kubernetes Secret containing the Alertmanager configuration with the Slack receiver |
| `cpu-alert-rule.yml` | PrometheusRule CRD defining the high CPU alert |
| `high-cpu-deployment.yaml` | Stress deployment designed to push CPU above the alert threshold |

## alertmanager-config.yml

Stored as a Kubernetes `Secret` (not a ConfigMap) because the Slack webhook URL is sensitive. Alertmanager reads its config from a Secret by default.

- namespace: `monitoring`
- update `api_url` on the Slack config with your actual webhook URL before applying

## cpu-alert-rule.yml

The PromQL expression fires when CPU usage exceeds a threshold for 1 continuous minute:

```yaml
expr: rate(container_cpu_usage_seconds_total[2m]) > 1
for: 1m
labels:
  severity: critical
```

The threshold is set to `> 1` (1% of a core) for testing only. In production set this to something like `> 0.8` (80% of a core).

## Deploy

```bash
kubectl apply -f alertmanager-config.yml
kubectl apply -f cpu-alert-rule.yml
kubectl apply -f high-cpu-deployment.yaml
```

## Restart Alertmanager to Pick Up the New Secret

Alertmanager reads its config at startup. After applying the new Secret, find and delete the pod to force a restart:

```bash
kubectl get pods -n monitoring

kubectl delete pod <alertmanager-pod-name> -n monitoring

# Confirm it restarts cleanly
kubectl get pods -n monitoring
```

## Validate

Once the stress deployment is running and Prometheus has evaluated the rule for at least 1 minute, a `critical` alert fires. Alertmanager routes it to the configured Slack channel via the webhook URL.

Check the Alertmanager UI (port-forward to port 9093) to see active alerts before Slack confirms delivery:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
```

Open `http://localhost:9093` to inspect alert state.

## CKAD Note

Wiring Alertmanager to Slack via a webhook is real-world integration work and is **not** examinable. The reusable CKAD skills hide inside the mechanics of this demo, not the Slack pipeline.

- Storing sensitive config (a webhook URL) in a `Secret` rather than a `ConfigMap` is a core exam concept.
- Forcing a pod to reload config by `kubectl delete pod <name> -n monitoring` and confirming the restart with `kubectl get pods -n monitoring` are genuine exam techniques.
- `kubectl port-forward svc/... 9093:9093 -n monitoring` to reach a service locally is in-scope; the PromQL alert rule and Slack routing are background only.

## Key Takeaway

Routing alerts to Slack is production integration, but the transferable CKAD lessons are using a `Secret` for sensitive data, restarting a pod to pick up new config, and port-forwarding to a Service — not the alert pipeline itself.
