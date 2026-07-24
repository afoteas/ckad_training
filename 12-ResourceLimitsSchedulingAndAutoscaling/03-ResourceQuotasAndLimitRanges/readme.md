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
4. Deploy a test workload (see `02-SettingRequestsAndLimitsInPods` for examples).
5. Observe admission behavior when rules are violated.

## Demo Files

- `resourcequota-dev.yaml` – ResourceQuota manifest
- `limitrange-dev.yaml` – LimitRange manifest

## Example Commands

```bash
kubectl create namespace dev
kubectl apply -f resourcequota-dev.yaml -n dev
kubectl apply -f limitrange-dev.yaml -n dev

kubectl get resourcequota -n dev
kubectl describe resourcequota -n dev
kubectl get limitrange -n dev
kubectl describe limitrange -n dev

# Deploy a test workload from 02-SettingRequestsAndLimitsInPods
kubectl apply -f ../02-SettingRequestsAndLimitsInPods/constrained-app.yaml -n dev
kubectl get deployment -n dev
```

## CKAD Tips

- Both objects are namespaced — always include `-n <namespace>` on `apply` and `get`/`describe`.
- `kubectl describe resourcequota -n dev` shows **Used vs Hard** — the fastest way to see remaining budget.
- With a quota on `requests`/`limits`, Pods that omit those fields are **rejected** unless a `LimitRange` supplies defaults.
- `LimitRange` uses `default` (limits), `defaultRequest` (requests), plus per-container `min`/`max`.
- Quota violations fail at admission — the `kubectl apply` error names the offending resource.

## Key Takeaway

`ResourceQuota` enforces tenant-level budget boundaries, while `LimitRange` enforces safe per-workload defaults and limits.
