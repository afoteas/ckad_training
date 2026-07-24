# Understanding Resource Requests and Limits

Resource management is a foundational Kubernetes operations skill. Correct CPU and memory settings help keep clusters stable, fair, and cost-efficient.

## Why This Matters

Every node has finite CPU and memory. Without constraints, one noisy workload can consume excessive resources and degrade or crash other services.

## Requests vs Limits

### Requests

- Scheduling baseline and guaranteed minimum.
- Kubernetes scheduler uses requests to decide Pod placement.
- If no node can satisfy the request, the Pod stays `Pending`.

### Limits

- Runtime hard cap.
- CPU above limit gets throttled.
- Memory above limit can trigger OOM kill.

## Typical Example Values

- request CPU: `250m`
- limit CPU: `500m`
- request memory: `256Mi`
- limit memory: `512Mi`

This allows burst usage above request (when capacity exists) while still enforcing a maximum boundary.

## Example Pod Spec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-demo
spec:
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "500m"
          memory: "512Mi"
```

## Operational Risks

- No requests and limits: unstable noisy-neighbor behavior.
- Overstated requests: wasted reserved capacity and higher cost.
- Limits too low: throttling, latency, and crashes.

## Best Practices

- Use historical metrics (Prometheus, Grafana, or equivalent) to size values.
- Tune continuously as traffic and behavior change.
- Keep development and production resource profiles separate.

## CKAD Tips

- Add resources fast on an existing workload: `kubectl set resources deployment <name> --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi`.
- Requests drive scheduling; limits enforce runtime — memory over limit is **OOMKilled**, CPU over limit is **throttled** (never killed).
- CPU is compressible, memory is not — remember this distinction for exam scenarios.
- A Pod whose CPU and memory `requests` equal its `limits` gets `Guaranteed` QoS; check with `kubectl describe pod`.
- If no node can satisfy the requests, the Pod stays `Pending` — read `kubectl describe pod` Events.

## Key Takeaway

Requests drive scheduling guarantees. Limits enforce runtime fairness. Both are needed for reliable multi-tenant Kubernetes clusters.
