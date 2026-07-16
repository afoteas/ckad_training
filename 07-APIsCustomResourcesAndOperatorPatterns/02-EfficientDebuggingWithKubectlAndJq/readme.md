# Efficient Debugging with kubectl & jq

This lesson shows how to combine `kubectl -o json` with `jq` so you can turn large Kubernetes object payloads into focused debugging views.

## Why Use jq?

- raw JSON from kubectl contains far more metadata than humans can scan quickly
- `jq` helps you filter, format, and select only the fields you need
- this is useful for incident response, scripts, dashboards, and shell loops

## Start with JSON Output

```bash
kubectl get pods -n demo -o json
```

From there, pipe the output into `jq`.

## Extract Pod Names

```bash
kubectl get pods -n demo -o json | jq -r '.items[].metadata.name'
```

## Extract Pod Names with Status

```bash
kubectl get pods -n demo -o json | jq -r '.items[] | "\(.metadata.name) \(.status.phase)"'
```

## Filter by Label

Return only pods where `app=nginx`:

```bash
kubectl get pods -n demo -o json | jq -r '.items[] | select(.metadata.labels.app == "nginx") | .metadata.name'
```

## Show Pod Name and IP

```bash
kubectl get pods -n demo -o json | jq -r '.items[] | "\(.metadata.name): \(.status.podIP)"'
```

## Show Pod Name and Container Image

```bash
kubectl get pods -n demo -o json | jq -r '.items[] | "\(.metadata.name): \(.spec.containers[].image)"'
```

## Inspect Requests and Limits

You can query CPU and memory requests or limits per pod to spot sizing issues.

```bash
kubectl get pods -n demo -o json | jq -r '.items[] |
  .metadata.name,
  "cpu request: \(.spec.containers[].resources.requests.cpu)",
  "cpu limit: \(.spec.containers[].resources.limits.cpu)",
  "memory request: \(.spec.containers[].resources.requests.memory)",
  "memory limit: \(.spec.containers[].resources.limits.memory)",
  ""'
```

## List Unique Images

```bash
kubectl get pods -n demo -o json | jq -r '.items[].spec.containers[].image' | sort -u
```

## Watch Changes Live

```bash
kubectl get pods -n demo -w
```

This gives you a live view while resources are created, updated, or deleted.

## Scale a Deployment Quickly

```bash
kubectl scale deployment nginx -n demo --replicas=5
```

Verify the result:

```bash
kubectl get deployment nginx -n demo -o json | jq '.spec.replicas, .status.replicas, .status.readyReplicas'
```

## Key Takeaways

- use `kubectl -o json` when default output hides useful fields
- use `jq` to extract names, status, labels, images, and resource settings
- use `-w` to watch live changes during updates
- use scale plus JSON verification for fast operational changes