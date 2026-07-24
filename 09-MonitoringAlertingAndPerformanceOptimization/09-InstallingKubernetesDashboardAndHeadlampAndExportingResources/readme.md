# Installing Kubernetes Dashboard and Headlamp and Exporting Resources

This demo installs Kubernetes Dashboard and Headlamp using Helm, then shows how to expose and export both rendered manifests and live cluster resources.

Note: Kubernetes Dashboard is archived (no longer actively maintained). For a maintained Kubernetes UI, consider Headlamp.

## Install

```bash
# Add the Helm repository
helm repo add kubernetes-dashboard https://kubernetes-retired.github.io/dashboard/

# Update to pull the latest chart metadata
helm repo update

# Install Dashboard into a dedicated namespace
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --create-namespace --namespace kubernetes-dashboard
```

The `--create-namespace` flag creates the `kubernetes-dashboard` namespace automatically.

## Verify Pods

```bash
kubectl get pods --namespace kubernetes-dashboard
```

Wait until Dashboard pods are in `Running` state.

## Create an Admin User (Lab/Training)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

This grants broad privileges and is intended for local labs only.

## Retrieve Login Token

```bash
kubectl --namespace kubernetes-dashboard create token admin-user
```

Copy the token output and keep it for the login step.

## Expose Dashboard Locally

```bash
# Confirm the service name
kubectl get svc --namespace kubernetes-dashboard

# Port-forward the Dashboard proxy service
kubectl port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 --namespace kubernetes-dashboard
```

Open `https://localhost:8443` and log in using the token from the previous step.

If your service name is different, use the service name shown by `kubectl get svc`.

## Export Dashboard Manifests (Rendered from Helm)

```bash
helm template kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --namespace kubernetes-dashboard > dashboard-rendered.yaml
```

This exports the rendered YAML exactly as Helm would apply it.

## Export Live Dashboard Resources (From Cluster)

```bash
kubectl get all,sa,secret,configmap,role,rolebinding,clusterrole,clusterrolebinding \
  --namespace kubernetes-dashboard -o yaml > dashboard-live.yaml
```

This captures currently running Dashboard resources and related RBAC objects.

## Install Headlamp

```bash
# Add the Headlamp Helm repository
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/

# Update chart metadata
helm repo update

# Install Headlamp into a dedicated namespace
helm install headlamp headlamp/headlamp \
  --create-namespace --namespace headlamp
```

The default chart creates a `ClusterRoleBinding` to `cluster-admin` for the Headlamp service account.

## Verify Headlamp Pods

```bash
kubectl get pods --namespace headlamp
```

Wait until the Headlamp pod is in `Running` state.

## Retrieve Headlamp Login Token

```bash
kubectl create token headlamp --namespace headlamp
```

Copy the token output and keep it for the login step.

## Expose Headlamp Locally

```bash
kubectl port-forward svc/headlamp 8080:80 --namespace headlamp
```

Open `http://localhost:8080` and log in with the token from the previous step.

## Export Headlamp Manifests (Rendered from Helm)

```bash
helm template headlamp headlamp/headlamp \
  --namespace headlamp > headlamp-rendered.yaml
```

## Export Live Headlamp Resources (From Cluster)

```bash
kubectl get all,sa,secret,configmap,role,rolebinding,clusterrole,clusterrolebinding \
  --namespace headlamp -o yaml > headlamp-live.yaml
```

## Optional Cleanup

```bash
helm uninstall kubernetes-dashboard --namespace kubernetes-dashboard
kubectl delete namespace kubernetes-dashboard

helm uninstall headlamp --namespace headlamp
kubectl delete namespace headlamp
```

## CKAD Note

Installing web UIs (Kubernetes Dashboard, Headlamp) via Helm is real-world tooling and is **not** examinable, but several `kubectl` patterns used here *are* squarely in scope.

- Exporting live resources with `kubectl get all,sa,secret,configmap,role,rolebinding,... -o yaml` is a genuine CKAD skill — practice `-o yaml` and multi-resource `get` queries.
- Creating short-lived credentials with `kubectl create token <sa> -n <ns>`, and the `ServiceAccount` + `ClusterRoleBinding` RBAC pattern, are examinable.
- `kubectl port-forward svc/... -n <ns>` to reach a service locally is in-scope; the Dashboard/Headlamp UIs themselves and `helm template` rendering are background only.

## Key Takeaway

The UIs are optional real-world tooling, but this chapter surfaces the truly examinable skills: exporting resources with `kubectl get -o yaml`, minting tokens with `kubectl create token`, wiring RBAC via `ServiceAccount`/`ClusterRoleBinding`, and port-forwarding to a Service.
