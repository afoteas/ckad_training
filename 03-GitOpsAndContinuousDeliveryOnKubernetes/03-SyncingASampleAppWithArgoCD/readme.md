# Syncing a Sample App with Argo CD

## Overview

In this section you connect a Git repository path to an Argo CD Application and observe initial and subsequent sync behavior.

## What You Should Know

- An Application links repo URL, revision, path, and destination cluster/namespace.
- Sync policies can be manual or automated.
- Automated sync with prune and self-heal is common for mature GitOps setups.
- Sync history helps diagnose regressions quickly.

## Minimal Application Concepts

- Source: repository, revision, directory or chart.
- Destination: cluster API target and namespace.
- Policy: auto-sync, prune obsolete resources, self-heal drift.

## Practical Tips

- Start with manual sync to understand behavior.
- Enable auto-sync after validation.
- Keep one logical app per Application to simplify ownership.
- Add namespace creation option only when needed.

## Quick Validation Checklist

- App status is Synced.
- App health is Healthy.
- Workloads, services, and ingress objects exist as expected.

## Commands
```bash
kubectl port-forward service/argocd-server -n argocd 8080:80
argocd login 127.0.0.1:8080 \
  --username admin \
  --plaintext \
  --grpc-web \
  --skip-test-tls

```

## Use a Real GitHub Repo (Recommended)

This is the standard GitOps workflow and works the same on Docker Desktop Kubernetes, Minikube, or any other cluster.

### 1. Choose the path inside your GitHub repo

Example from this training repository:

```bash
WorkloadandContainerImageFundamentals/CreatePVCAndMountItToDeployment
```

### 2. Register the GitHub repository in Argo CD


For a private repo (HTTPS + PAT):

```bash
export GITHUB_PAT="YOUR_GITHUB_PAT"

argocd repo add https://github.com/afoteas/ckad_training.git \
  --username afoteas \
  --password "$GITHUB_PAT" \
  --insecure-skip-server-verification
```

### 3. Create and sync the Application

```bash
argocd app create ckad-sample \
  --repo https://github.com/afoteas/ckad_training.git \
  --path WorkloadandContainerImageFundamentals/CreatePVCAndMountItToDeployment \
  --revision main \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

argocd app sync ckad-sample
argocd app get ckad-sample
```

### 4. Enable automated sync (optional)

```bash
argocd app set ckad-sample --sync-policy automated --self-heal --auto-prune
```

### 5. Delete the Application

Delete app and all resources it created:

```bash
argocd app delete ckad-sample --cascade --yes
```

Delete only the Argo CD Application object and keep deployed resources:

```bash
argocd app delete ckad-sample --cascade=false --yes
```

Quick check:

```bash
argocd app list
```

## Notes

- You no longer need local hostPath mounts when using GitHub.
- Keep credentials out of shell history when using private repos.
- If your default branch is not `main`, replace `--revision main` with the correct branch.
- If your organization uses TLS interception (for example Zscaler), add the corporate root CA to Argo CD before adding HTTPS repos.

## CKAD Note

Argo CD `Application` objects, auto-sync/prune/self-heal policies, and the `argocd app` CLI are **not** examinable — this is GitOps tooling, not core Kubernetes.

- The examinable equivalent of a "synced app" is deploying manifests yourself with `kubectl apply -f <dir>` (or `-k` for Kustomize) and confirming health with `kubectl get`, `kubectl rollout status`, and `kubectl describe`.
- "Prune obsolete resources" maps to the exam concept of `kubectl delete`/`kubectl apply --prune`; "self-heal drift" is what a controller does automatically — on the exam you reconcile manually.
- Understand the mental model (source repo + path + destination namespace) but expect to be tested on the underlying resources (Deployments, Services, Ingress), not on Argo CD Applications.

## Key Takeaway

An Argo CD Application binds a repo path to a destination cluster/namespace and continuously syncs it; for CKAD you should be able to deploy and verify those same workloads directly with `kubectl apply` and `kubectl get`/`rollout status` rather than through Argo CD.
