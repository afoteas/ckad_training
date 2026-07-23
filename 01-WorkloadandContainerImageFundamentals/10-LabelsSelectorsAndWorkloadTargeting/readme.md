# Labels, Selectors, and Workload Targeting

Labels are key/value pairs on Kubernetes objects. **Selectors** use those labels to connect workloads to Services, NetworkPolicies, affinity rules, and controllers.

Almost every CKAD task involves labels — fixing a broken selector is one of the fastest ways to recover points on the exam.

## How Labels Are Used

| Consumer | Field | Purpose |
|----------|-------|---------|
| Deployment / StatefulSet | `spec.selector.matchLabels` | Which Pods this controller owns |
| Pod template | `metadata.labels` | Must match the controller selector |
| Service | `spec.selector` | Which Pods receive traffic |
| NetworkPolicy | `podSelector` / `from` | Which Pods are affected or allowed |
| Affinity | `labelSelector` | Co-locate or spread Pods |

**Rule:** `spec.selector.matchLabels` on a Deployment must be a **subset** of `spec.template.metadata.labels`. They do not have to be identical — the template can have extra labels.

## matchLabels vs matchExpressions

```yaml
# Simple — exact key/value match
matchLabels:
  app: web

# Flexible — operators
matchExpressions:
- key: tier
  operator: In
  values: [frontend, api]
- key: environment
  operator: NotIn
  values: [dev]
```

Operators: `In`, `NotIn`, `Exists`, `DoesNotExist`.

## Common Exam Mistakes

1. **Service has no endpoints** — Service `selector` does not match Pod labels (`kubectl get endpoints`).
2. **Deployment creates no Pods** — `selector` and template labels disagree.
3. **NetworkPolicy has no effect** — wrong `podSelector` label (policy still applies; traffic rule is wrong).
4. **Typo in label key** — `app:web` vs `app: web` is fine, but `app` vs `application` breaks matching.

## Demo Files

| File | Purpose |
|------|---------|
| `labeled-deployment.yaml` | Deployment with `app: web` and `tier: frontend` |
| `matching-service.yaml` | Service selector matches the Deployment Pods |
| `broken-service.yaml` | Wrong selector — results in empty Endpoints |

## Step 1: Deploy Labeled Workload

```bash
kubectl apply -f labeled-deployment.yaml
kubectl get pods --show-labels
```

## Step 2: Service With Matching Selector

```bash
kubectl apply -f matching-service.yaml
kubectl get endpoints matching-svc
```

Endpoints should list Pod IPs.

## Step 3: Broken Selector (Troubleshooting Drill)

```bash
kubectl apply -f broken-service.yaml
kubectl get endpoints broken-svc
```

Endpoints are empty. Fix by aligning `spec.selector` with Pod labels:

```bash
kubectl edit svc broken-svc
# change selector to: app: web
kubectl get endpoints broken-svc
```

## Imperative Label Commands

```bash
kubectl label pod <name> env=prod
kubectl label pod <name> env-          # remove label
kubectl label nodes <node> disktype=ssd --overwrite
```

## CKAD Tips

- Verify Services with `kubectl get endpoints <svc-name>`.
- Deployment selector is **immutable** — you cannot change it after creation; recreate the Deployment if wrong.
- Prefer consistent label keys (`app`, `tier`, `env`) across the namespace.

## Key Takeaway

Labels connect objects. If traffic, policies, or controllers misbehave, compare the **selector on the consumer** with the **labels on the target Pods** first.
