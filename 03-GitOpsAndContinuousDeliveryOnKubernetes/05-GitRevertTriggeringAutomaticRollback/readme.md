# Git Revert Triggering Automatic Rollback

## Overview

In GitOps, rollback is usually a Git operation. Reverting the commit that introduced a bad change causes controllers to reconcile the cluster back to the previous desired state.

## What You Should Know

- Rollback should happen through Git history, not manual kubectl edits.
- A revert commit keeps auditability intact.
- Auto-sync applies the rollback quickly after merge.
- Incident timelines are easier to reconstruct with commit-based remediation.

## Typical Rollback Flow

1. Identify problematic commit.
2. Run git revert on that commit.
3. Merge revert PR after review.
4. Confirm controller syncs to reverted state.
5. Validate app health and user impact resolved.

## Install Argo CD (If Needed)

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl apply -f argocd-application.yaml
```

## Trigger Sync and Verify

```bash
kubectl get application nginx-app -n argocd
kubectl patch application nginx-app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
kubectl wait --for=condition=ready pod -l app=guestbook-ui -n default --timeout=120s
kubectl get application nginx-app -n argocd
kubectl get pods -n default
```

## Simulate a Failed Release (Bad Image Tag)

```bash
kubectl set image deployment/guestbook-ui guestbook-ui=gcr.io/heptio-images/ks-guestbook-demo:bad-tag -n default
kubectl get pods -n default
kubectl get application nginx-app -n argocd
kubectl patch application nginx-app -n argocd --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
kubectl get application nginx-app -n argocd
```

Expected result:

- New `guestbook-ui` pod can enter `ErrImagePull` or `ImagePullBackOff`.
- This creates a realistic failure condition before performing a rollback via Git revert.

## Troubleshooting: GitHub TLS Error in Corporate Network

If the Application shows an error like `x509: certificate signed by unknown authority`, the issue is usually TLS interception (for example Zscaler) and not the Application YAML itself.

What happened in this lab:

- Argo CD could not verify the certificate chain when reading `https://github.com/argoproj/argocd-example-apps`.
- A wrong certificate entry for `github.com` existed in Argo CD trust settings.

Temporary fix used:

```bash
argocd repo add https://github.com/argoproj/argocd-example-apps --insecure-skip-server-verification --upsert
argocd app get nginx-app --refresh
```

Why this worked:

- `--insecure-skip-server-verification` bypasses server certificate validation for that repo, so Argo CD can fetch refs and render manifests.

Recommended secure fix:

1. Add the correct corporate root/intermediate CA certificate to Argo CD for `github.com`.
2. Remove insecure repo mode after trust is configured correctly.

```bash
argocd repo rm https://github.com/argoproj/argocd-example-apps
argocd repo add https://github.com/argoproj/argocd-example-apps
```

## Practical Tips

- Prefer revert over force-push to preserve traceability.
- Add incident reference in revert commit message.
- Use protected branches to avoid direct emergency edits.
