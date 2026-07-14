# Container Logging in Kubernetes

Kubernetes logging starts with application output to stdout/stderr and extends to cluster-wide collection and central storage.

## Standard Model

1. App writes logs to stdout/stderr.
2. Container runtime stores structured log files on node.
3. `kubectl logs` reads those logs through Kubernetes API.
4. Log agents forward logs to centralized backends.

## Common Collection Patterns

- sidecar log collector per pod
- node-level DaemonSet collectors (for example Fluentd/Filebeat)
- central backends (Elasticsearch, Splunk, Cloud Logging)

## Best Practices

- use structured logs (JSON with labels like level, requestId)
- avoid over-verbose debug logs in production
- enforce retention and access policy requirements
- aggregate quickly to avoid node-loss log gaps
