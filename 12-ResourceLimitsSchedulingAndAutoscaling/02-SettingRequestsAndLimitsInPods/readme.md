# Setting Requests and Limits in Pods

This lesson demonstrates how to set CPU and memory requests and limits in a Deployment and verify that Kubernetes enforces them.

## Demo Goal

Deploy an `nginx` workload with explicit resource constraints so it behaves as a fair tenant in a shared cluster.

## Example Pattern

In the container `resources` block:

- requests: `cpu: 100m`, `memory: 64Mi`
- limits: `cpu: 200m`, `memory: 128Mi`

## Demo Flow

1. Create a deployment manifest (for example `constrained-nginx-deployment.yaml`) with `resources.requests` and `resources.limits`.
2. Apply the deployment.
3. Confirm deployment status.
4. Inspect Pod details and verify requests/limits are present.

## Example Commands

```bash
kubectl apply -f constrained-nginx-deployment.yaml
kubectl get deployment constrained-nginx-deployment
kubectl get pods

POD=$(kubectl get pods -l app=constrained-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD"
```

## What to Verify

- Pod is `Running`.
- `kubectl describe pod` shows both requests and limits under the container.
- The values match your manifest.

## Key Takeaway

Setting requests and limits in manifests makes scheduling predictable and prevents one workload from monopolizing node resources.
