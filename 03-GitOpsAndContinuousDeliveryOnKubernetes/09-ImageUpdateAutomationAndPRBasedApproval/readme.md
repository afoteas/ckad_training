# Image Update Automation and PR-Based Approval

## Overview

This section shows a minimal Flux image automation setup that watches a container registry, selects allowed versions, and updates Git manifests.

For PR-based approval, the automation should push to a dedicated branch, and merge to `main` should happen only through reviewed pull requests.

## What You Should Know

- Automation should update manifests, not deploy directly to production.
- PR-based approval keeps compliance and audit requirements intact.
- Version policies can restrict updates to patch or minor streams.
- Rollback remains a simple Git revert.

## Files in This Folder

- `deployment.yaml`: workload manifest with an image policy setter comment.
- `imagerepository.yaml`: tells Flux where to scan image tags.
- `imagepolicy.yaml`: chooses which tag is valid (semantic version range).
- `imageupdateautomation.yaml`: commits image updates back to Git.

## Safe Automation Model

1. Registry gets new image tag.
2. Flux image repository scan detects the tag.
3. Flux image policy selects an allowed tag.
4. Flux image automation updates `deployment.yaml` in Git.
5. Automation branch is reviewed and merged to `main`.
6. GitOps controller syncs merged change.

## Apply the Image Automation Resources

```bash
flux install --components=source-controller,kustomize-controller,helm-controller,notification-controller,image-reflector-controller,image-automation-controller
flux check
kubectl apply -f imagerepository.yaml
kubectl apply -f imagepolicy.yaml
kubectl apply -f imageupdateautomation.yaml
kubectl apply -f deployment.yaml
```

## Verify

```bash
kubectl get imagerepositories.image.toolkit.fluxcd.io -n flux-system
kubectl get imagepolicies.image.toolkit.fluxcd.io -n flux-system
kubectl get imageupdateautomations.image.toolkit.fluxcd.io -n flux-system
kubectl get deployment podinfo -n default
```

## Important for PR-Based Approval

The included `imageupdateautomation.yaml` is a working baseline. For strict PR-based flow, change `spec.git.push.branch` from `main` to a dedicated branch (for example `flux-image-updates`) and use your Git provider workflow to open a PR from that branch to `main`.

If you keep pushing directly to `main`, updates are automatic but no human approval gate is enforced.

## Practical Tips

- Use semantic version filters where possible.
- Block mutable tags like latest in production.
- Require status checks before merge.
- Include changelog or release notes in automated PR body.
