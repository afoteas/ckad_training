# Installing Argo CD on a Cluster

## Overview

Argo CD is a GitOps controller for Kubernetes that syncs application definitions from Git to one or more clusters. In this section, you install Argo CD with Helm, expose the API server locally, and log in with the CLI.

## What You Should Know

- Argo CD is usually installed in argocd namespace.
- Helm values let you customize service type, ports, and server behavior during install.
- The API server and UI are useful for observing sync and health status.
- Initial admin secret must be rotated after first login.
- RBAC should be configured early for teams and environments.

## Common Install Flow

1. Create argocd namespace.
2. Add the Argo Helm repository and update local chart metadata.
3. Install Argo CD with your custom values file.
4. Retrieve the initial admin password.
5. Expose the server locally with port-forward.
6. Log in with the Argo CD CLI and rotate the password.

## Why This Setup Works

- Your [argocd-values.yaml](GitOpsAndContinuousDeliveryOnKubernetes/02-InstallingArgoCDOnACluster/argocd-values.yaml) sets `server.insecure: true`, so the Argo CD server listens without TLS.
- Because of that, the CLI must use `--plaintext` instead of `--insecure`.
- In this environment, `--grpc-web --skip-test-tls` was also needed for the CLI login to succeed reliably.
- The service exposes port `80`, which maps to container port `8080`, so the local port-forward uses `8080:80`.

## Commands

```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd --values argocd-values.yaml
```

```bash
kubectl -n argocd get pods
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
kubectl port-forward service/argocd-server -n argocd 8080:80
```

```bash
argocd login 127.0.0.1:8080 \
	--username admin \
	--plaintext \
	--grpc-web \
	--skip-test-tls
```

If you prefer to pass the password directly:

```bash
argocd login 127.0.0.1:8080 \
	--username admin \
	--password "$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)" \
	--plaintext \
	--grpc-web \
	--skip-test-tls
```

```bash
argocd account update-password
kubectl delete secret argocd-initial-admin-secret -n argocd
```

## Validation Checklist

- `kubectl -n argocd get pods` shows all Argo CD pods in `Running` state.
- `kubectl port-forward` stays up while the CLI connects.
- `argocd login` succeeds and stores the context locally.
- You can run `argocd account get-user-info` after login.

## Practical Tips

- Pin Argo CD version for predictable behavior.
- Avoid hardcoding the admin password in notes or shell history when possible.
- Back up Argo CD settings and projects.
- Use projects to isolate environments and repo access.

## CKAD Note

Installing and operating Argo CD is **not** on the CKAD exam. Argo CD is real-world GitOps tooling, and the `argocd` CLI, `Application` CRD, and initial-admin-secret rotation are outside exam scope.

- What IS examinable here: installing charts with Helm (`helm repo add`, `helm repo update`, `helm install --values`) and working with namespaces (`kubectl create namespace`).
- Reading Secrets is in-scope: `kubectl get secret ... -o jsonpath="{.data.password}" | base64 -d` is a genuinely useful CKAD skill.
- `kubectl port-forward service/... 8080:80` (local access + target-port mapping) is examinable and worth memorizing.

## Key Takeaway

This section installs Argo CD via Helm and logs in with the CLI; for CKAD the transferable skills are Helm chart installs with a custom values file, namespace creation, decoding Secrets, and `kubectl port-forward` — not Argo CD itself.
