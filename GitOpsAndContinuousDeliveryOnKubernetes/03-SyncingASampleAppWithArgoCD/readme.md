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

For a public repo:

```bash
argocd repo add https://github.com/OWNER/REPO.git
```

For a private repo (HTTPS + PAT):

```bash
argocd repo add https://github.com/OWNER/REPO.git \
  --username YOUR_GITHUB_USERNAME \
  --password YOUR_GITHUB_PAT
```

### 3. Create and sync the Application

```bash
argocd app create ckad-sample \
  --repo https://github.com/OWNER/REPO.git \
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

## Notes

- You no longer need local hostPath mounts when using GitHub.
- Keep credentials out of shell history when using private repos.
- If your default branch is not `main`, replace `--revision main` with the correct branch.