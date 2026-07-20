# Resource Quotas and Limit Ranges

Resource governance in shared clusters depends on two namespace-level controls: `ResourceQuota` and `LimitRange`.

## Why They Are Needed

In multi-tenant environments, uncontrolled workloads can consume excessive resources and impact other teams.

- `ResourceQuota` caps total namespace consumption.
- `LimitRange` enforces defaults and min/max boundaries per container.

## ResourceQuota

Use `ResourceQuota` to cap aggregate usage in a namespace, such as:

- total requested CPU and memory
- total CPU and memory limits
- object counts like Pods, PVCs, and Services

If creating a resource would exceed quota, the API server denies it.

## LimitRange

Use `LimitRange` to:

- set default requests/limits when omitted
- enforce minimum and maximum allowed values

This prevents unconstrained Pods and unrealistic sizing.

## Example Workflow

1. Create target namespace (for example `dev`).
2. Apply a `ResourceQuota` for namespace budget.
3. Apply a `LimitRange` for per-container guardrails.
4. Create Pods and observe default injection or admission denial when rules are violated.

## Example Commands

```bash
kubectl create namespace dev
kubectl apply -f resourcequota-dev.yaml
kubectl apply -f limitrange-dev.yaml

kubectl get resourcequota -n dev
kubectl describe resourcequota -n dev
kubectl get limitrange -n dev
kubectl describe limitrange -n dev
```

## Key Takeaway

`ResourceQuota` enforces tenant-level budget boundaries, while `LimitRange` enforces safe per-workload defaults and limits.
