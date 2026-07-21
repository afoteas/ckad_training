# Creating Aggregated Roles and Scoped SA

This lesson demonstrates creating aggregated ClusterRoles and binding them to a scoped ServiceAccount, plus testing permissions with impersonation.

For background on aggregation and impersonation concepts, see [07-AdvancedRBACAggregationAndImpersonation](../07-AdvancedRBACAggregationAndImpersonation/readme.md).

## Demo Files

- `custom-clusterroles.yaml` — three contributing ClusterRoles
- `monitoring-viewer-clusterrole.yaml` — aggregated ClusterRole
- `scoped-serviceaccount.yaml` — ServiceAccount for monitoring
- `rolebinding.yaml` — binds the aggregated role to the SA

## RBAC Components Recap

| Resource | Scope | Purpose |
|----------|-------|---------|
| `Role` | Namespace | Permissions within one namespace |
| `ClusterRole` | Cluster-wide | Permissions across the cluster |
| `RoleBinding` | Namespace | Grants a Role to a subject |
| `ClusterRoleBinding` | Cluster-wide | Grants a ClusterRole to a subject |

## Role Aggregation

Aggregation lets you **compose** a ClusterRole from multiple smaller ClusterRoles using label selectors:

- **Modularity** — define permissions in small, reusable pieces
- **Dynamic composition** — roles update automatically when new matching ClusterRoles are created

Kubernetes uses this for built-in roles like `admin`, `edit`, and `view`.

## Step 1: Inspect Built-in Aggregated Roles

View how the built-in `view` role uses aggregation:

```bash
kubectl get clusterrole view -o yaml
```

Look for:

```yaml
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
```

Find ClusterRoles that contribute to `view`:

```bash
kubectl get clusterrole -l rbac.authorization.k8s.io/aggregate-to-view=true
```

View the merged rules:

```bash
kubectl get clusterrole view -o jsonpath='{.rules}' | jq .
```

## Step 2: Create Contributing ClusterRoles

Apply three focused ClusterRoles, each labeled for aggregation:

```bash
kubectl apply -f custom-clusterroles.yaml
```

| ClusterRole | Permissions | Label |
|-------------|-------------|-------|
| `pod-reader` | Read Pods and logs | `aggregate-monitoring: "true"` |
| `service-reader` | Read Services and Endpoints | `aggregate-monitoring: "true"` |
| `deployment-reader` | Read Deployments and ReplicaSets | `aggregate-monitoring: "true"` |

Verify:

```bash
kubectl get clusterrole pod-reader service-reader deployment-reader --show-labels
```

## Step 3: Create the Aggregating ClusterRole

```bash
kubectl apply -f monitoring-viewer-clusterrole.yaml
```

The `monitoring-viewer` role uses:

```yaml
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.example.com/aggregate-monitoring: "true"
rules: []  # populated automatically by the controller
```

Wait a moment for aggregation, then inspect the merged rules:

```bash
kubectl get clusterrole monitoring-viewer -o yaml
```

Expected behavior: the `rules` section is automatically populated with permissions from all three contributing ClusterRoles.

## Step 4: Create Scoped ServiceAccount and Bind It

```bash
kubectl apply -f scoped-serviceaccount.yaml
kubectl apply -f rolebinding.yaml
```

This grants the `monitoring-viewer` aggregated role to `monitoring-sa` in the `default` namespace.

## Step 5: Test Permissions with Impersonation

Test what the ServiceAccount can do without using its token directly:

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:default:monitoring-sa

kubectl auth can-i get deployments \
  --as=system:serviceaccount:default:monitoring-sa

kubectl auth can-i get secrets \
  --as=system:serviceaccount:default:monitoring-sa
```

Expected results:

| Resource | Allowed? |
|----------|----------|
| `pods` | Yes |
| `deployments` | Yes |
| `services` | Yes |
| `secrets` | No (not in aggregated rules) |

List resources as the ServiceAccount:

```bash
kubectl get pods --as=system:serviceaccount:default:monitoring-sa
kubectl get deployments --as=system:serviceaccount:default:monitoring-sa
```

## Optional Cleanup

```bash
kubectl delete -f rolebinding.yaml
kubectl delete -f scoped-serviceaccount.yaml
kubectl delete -f monitoring-viewer-clusterrole.yaml
kubectl delete -f custom-clusterroles.yaml
```

## Key Takeaway

Aggregated roles keep RBAC modular — add new contributing ClusterRoles with a label and the aggregated role updates automatically. Scoped ServiceAccounts limit blast radius by granting only the composed permissions a workload needs.
