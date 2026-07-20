# Configuring ServiceAccounts and RBAC for Applications

Kubernetes applications should run with the minimum permissions they need. This is achieved by combining a ServiceAccount, a Role, and a RoleBinding.

## The Problem

By default, Pods run with the namespace's default ServiceAccount. If a workload is compromised, it inherits whatever permissions that identity has.

That is why applications should use a custom ServiceAccount with narrowly scoped RBAC permissions.

## The Three Core Objects

### ServiceAccount

A ServiceAccount is the identity the Pod uses when talking to the Kubernetes API.

### Role

A Role defines the allowed actions on specific resources within a single namespace.

Examples:

- `get`
- `list`
- `watch`

### RoleBinding

A RoleBinding connects the Role to the ServiceAccount.

That link is what grants the permissions.

## Example Pattern

A common least-privilege pattern is:

1. create a ServiceAccount such as `pod-reader`
2. create a Role that only allows reading Pods
3. bind that Role to the ServiceAccount
4. reference that ServiceAccount from the Deployment

## Why the Deployment Must Reference the ServiceAccount

The Pod must explicitly use the intended ServiceAccount through `serviceAccountName`. Otherwise, Kubernetes uses the default ServiceAccount for the namespace.

That means the RBAC objects can be correct but still unused if the Deployment does not reference the right ServiceAccount.

## Demo Idea

A simple demo workload can run a lightweight container and use the custom ServiceAccount. From there, you can verify whether the workload can list Pods and confirm that the expected permissions are in effect.

Files in this lesson:

- `service-account.yaml`
- `pod-reader-role.yaml`
- `pod-reader-binding.yaml`
- `app-rbac-deployment.yaml`

Apply them in order:

```bash
kubectl apply -f service-account.yaml
kubectl apply -f pod-reader-role.yaml
kubectl apply -f pod-reader-binding.yaml
kubectl apply -f app-rbac-deployment.yaml
```

Verify the workload and its identity:

```bash
kubectl get pods -l app=rbac-demo
kubectl describe sa pod-reader
kubectl auth can-i list pods --as=system:serviceaccount:default:pod-reader
```

The Deployment manifest already references the custom ServiceAccount through `serviceAccountName: pod-reader`, which is the critical link that makes the RBAC policy apply to the Pod.

## Cleanup

```bash
kubectl delete -f app-rbac-deployment.yaml
kubectl delete -f pod-reader-binding.yaml
kubectl delete -f pod-reader-role.yaml
kubectl delete -f service-account.yaml
```

## Best Practices

- Never rely on the default ServiceAccount for application workloads.
- Grant only the permissions the app truly needs.
- Prefer namespace-scoped Roles over ClusterRoles when possible.
- Review RoleBindings regularly.
- Separate identities per application or per permission boundary.
- Keep RBAC resources under version control.

## Key Takeaway

RBAC for applications is built from three parts: identity, permissions, and binding. When a Deployment references a custom ServiceAccount with a narrowly scoped Role, the workload follows the principle of least privilege and becomes much safer to operate.