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

## Example: Using kubectl logs

```bash
# Get logs for a single Pod
kubectl logs my-pod

# Get logs for a specific container in a Pod
kubectl logs my-pod -c container-name

# Stream logs in real time
kubectl logs -f my-pod
```

## Best Practices

- use structured logs (JSON with labels like level, requestId)
- avoid over-verbose debug logs in production
- enforce retention and access policy requirements
- aggregate quickly to avoid node-loss log gaps

## CKAD Tips

- `kubectl logs` is core exam material: `kubectl logs <pod>`, `-c <container>` for multi-container pods, `-f` to stream, and `--previous` to read a crashed container's last logs.
- The golden rule: apps should log to **stdout/stderr** so the runtime and `kubectl logs` can capture them — file-based logging inside the container is invisible to `kubectl logs`.
- Use `kubectl logs -l app=<label> --tail=100` to grab logs across all pods of a Deployment in one command.
- Cluster-wide aggregation (Fluentd/Filebeat DaemonSets, Elasticsearch/Splunk) is real-world architecture, not something you configure in the exam — focus on retrieving logs, not building the pipeline.

## Key Takeaway

Kubernetes logging starts with containers writing to stdout/stderr; `kubectl logs` (with `-c`, `-f`, and `--previous`) is the primary tool you must be fluent with, while node-level agents handle centralized aggregation in production.
