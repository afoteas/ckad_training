# Troubleshooting RBAC with kubectl auth can-i

After creating ServiceAccounts, Roles, and RoleBindings, you need a fast way to verify **what a identity can do**. `kubectl auth can-i` answers that without guessing.

For creating RBAC objects, see [06-ConfiguringServiceAccountsAndRBACForApplications](../06-ConfiguringServiceAccountsAndRBACForApplications/readme.md).

## Quick Reference

```bash
# Can the current user list pods in default?
kubectl auth can-i list pods

# Can a ServiceAccount create deployments in dev?
kubectl auth can-i create deployments \
  --as=system:serviceaccount:dev:my-sa -n dev

# List everything the SA can do in a namespace
kubectl auth can-i --list \
  --as=system:serviceaccount:default:pod-reader -n default
```

## ServiceAccount Identity Format

```text
system:serviceaccount:<namespace>:<service-account-name>
```

## Demo: Verify Lesson 06 RBAC

If you applied the files from lesson 06:

```bash
kubectl auth can-i get pods \
  --as=system:serviceaccount:default:pod-reader -n default
# yes

kubectl auth can-i delete pods \
  --as=system:serviceaccount:default:pod-reader -n default
# no
```

## Common Exam Scenarios

1. **"Verify the SA can only read pods"** — use `can-i get/list/watch pods` → yes; `can-i delete pods` → no.
2. **"Fix RBAC so the app can read ConfigMaps"** — add `configmaps` to Role rules, then verify with `can-i get configmaps`.
3. **Wrong namespace** — RoleBinding must be in the same namespace as the Role and SA.

## Debugging Flow

```text
1. kubectl auth can-i <verb> <resource> --as=system:serviceaccount:...
2. If "no" → kubectl describe rolebinding / role
3. Check: correct SA? correct namespace? rule includes verb+resource?
4. Check Pod spec.serviceAccountName matches intended SA
```

## CKAD Tips

- `--as` simulates another user/SA without logging in as them.
- `kubectl auth can-i --list` shows all allowed verbs — faster than reading YAML during the exam.
- ClusterRole + ClusterRoleBinding use cluster-scoped resources; test without `-n` or with the right scope.

## Key Takeaway

`kubectl auth can-i` is the fastest way to confirm RBAC is correct. Always verify after creating Role/RoleBinding, especially under exam time pressure.
