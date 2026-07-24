# Setting Requests and Limits in Pods

This lesson demonstrates how to set CPU and memory requests and limits in a Deployment and verify that Kubernetes enforces them.

## Demo Goal

Deploy an `nginx` workload with explicit resource constraints so it behaves as a fair tenant in a shared cluster.

## Example Pattern

In the container `resources` block:

- requests: `cpu: 100m`, `memory: 64Mi`
- limits: `cpu: 200m`, `memory: 128Mi`

## Demo Flow

1. Use the provided deployment manifest `../03-ResourceQuotasAndLimitRanges/constrained-app.yaml` (or create your own) with `resources.requests` and `resources.limits`.
2. Apply the deployment.
3. Confirm deployment status.
4. Inspect Pod details and verify requests/limits are present.

## Example Commands

```bash
kubectl apply -f constrained-app.yaml
kubectl get deployment constrained-nginx-deployment
kubectl get pods

POD=$(kubectl get pods -l app=constrained-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD"
```

## What to Verify

- Pod is `Running`.
- `kubectl describe pod` shows both requests and limits under the container.
- The values match your manifest.

## CKAD Tips

- Verify quickly: `kubectl describe pod <pod>` shows `Requests:` and `Limits:` under each container.
- Edit an existing Deployment without touching YAML: `kubectl set resources deployment <name> --requests=cpu=100m,memory=64Mi --limits=cpu=200m,memory=128Mi`.
- Know the units: CPU `m` (millicores, `1000m` = 1 core); memory `Mi`/`Gi` (binary) vs `M`/`G` (decimal).
- Spot-check with `kubectl get pod <pod> -o jsonpath='{.spec.containers[0].resources}'`.
- Pods with no requests/limits are valid YAML but land in `BestEffort` QoS.

## Key Takeaway

Setting requests and limits in manifests makes scheduling predictable and prevents one workload from monopolizing node resources.
