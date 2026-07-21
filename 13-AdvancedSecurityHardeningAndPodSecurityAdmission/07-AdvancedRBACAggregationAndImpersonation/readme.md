# Advanced RBAC Aggregation and Impersonation

Up to this point we've secured Pods, containers, kernels, and the supply chain. This lesson focuses on **who can do what inside the cluster** using advanced RBAC patterns.

## RBAC at Scale

Kubernetes uses **Role-Based Access Control (RBAC)** to manage permissions. You are likely familiar with:

| Resource | Scope | Purpose |
|----------|-------|---------|
| `Role` | Namespace | Defines permissions within one namespace |
| `ClusterRole` | Cluster-wide | Defines permissions across the cluster |
| `RoleBinding` | Namespace | Grants a Role to a subject in a namespace |
| `ClusterRoleBinding` | Cluster-wide | Grants a ClusterRole to a subject cluster-wide |

In large clusters, basic RBAC becomes hard to manage:

- Hundreds of users, controllers, and ServiceAccounts
- Manual role assignment doesn't scale
- **Role sprawl** — impossible to track who has access to what
- Auditing and troubleshooting require testing as another identity

Kubernetes addresses this with **ClusterRole aggregation** and **impersonation**.

## ClusterRole Aggregation

Instead of maintaining one giant ClusterRole with every permission, Kubernetes can **automatically merge** smaller ClusterRoles into an aggregated role using labels.

### How It Works

1. Create small, focused ClusterRoles with a shared label.
2. Create an aggregating ClusterRole with an `aggregationRule` that selects those labels.
3. Kubernetes automatically merges all matching rules into the aggregated role.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: custom-view
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
```

The label `aggregate-to-view: "true"` tells Kubernetes to include these rules in the built-in `view` ClusterRole. Any user with `view` automatically gains read access to Deployments.

### Built-in Aggregated Roles

Kubernetes uses aggregation for built-in roles:

| Built-in role | Aggregation label |
|---------------|-------------------|
| `view` | `rbac.authorization.k8s.io/aggregate-to-view: "true"` |
| `edit` | `rbac.authorization.k8s.io/aggregate-to-edit: "true"` |
| `admin` | `rbac.authorization.k8s.io/aggregate-to-admin: "true"` |

Inspect the built-in `view` role:

```bash
kubectl get clusterrole view -o yaml
```

Look for `aggregationRule.clusterRoleSelectors` with `matchLabels`.

### Benefits

- **Modular** — define permissions in small, reusable pieces
- **Maintainable** — no need to edit built-in roles directly
- **Consistent** — new controllers auto-contribute to aggregated roles
- Ideal for **custom operators** that need their permissions included in standard roles

## Impersonation

Impersonation lets an administrator **act as another user or ServiceAccount** to test permissions or troubleshoot access issues — without needing their credentials.

```bash
kubectl --as=developer@example.com get pods
kubectl --as=system:serviceaccount:default:my-sa get pods
kubectl --as-group=system:authenticated get pods
```

### Use Cases

| Scenario | Command |
|----------|---------|
| Developer can't access pod logs | `kubectl --as=developer@example.com logs <pod>` |
| Test ServiceAccount permissions | `kubectl --as=system:serviceaccount:ns:sa-name get secrets` |
| Audit what a group can do | `kubectl --as-group=dev-team get deployments` |

### Required Permission

To impersonate, you need the `impersonate` verb:

```yaml
rules:
- apiGroups: [""]
  resources: ["serviceaccounts", "users", "groups"]
  verbs: ["impersonate"]
```

## Security and Operational Best Practices

| Practice | Why |
|----------|-----|
| Limit impersonation to cluster admins | Prevents privilege escalation |
| Audit impersonation via API server logs | Every impersonation request is logged |
| Document aggregated roles | Teams must understand which roles are composed and why |
| Avoid role sprawl | Group related permissions and reuse aggregated roles |
| Regularly review ClusterRoles | Remove unused roles; maintain least privilege |

## Key Takeaway

Aggregation keeps RBAC modular and scalable; impersonation enables safe permission testing without sharing credentials. Both are essential for managing access in large Kubernetes clusters.

For a hands-on walkthrough, see [08-CreatingAggregatedRolesAndScopedSA](../08-CreatingAggregatedRolesAndScopedSA/readme.md).
