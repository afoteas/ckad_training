# Bootstrap Flux and Deploy via Kustomize

## Overview

Bootstrapping Flux installs controllers and wires your cluster to a Git repository so that Kustomize manifests are applied automatically.

## What You Should Know

- Bootstrap creates Flux manifests in your repo.
- Kustomize overlays are ideal for environment-specific changes.
- Repository structure determines maintainability as scale grows.
- PR-driven updates become the default change path after bootstrap.

## Typical Bootstrap Steps

1. Install flux CLI locally.
2. Authenticate to Git provider.
3. Bootstrap Flux to target repo and branch.
4. Add app base and overlays.
5. Commit and push.
6. Verify reconciliation.

## Example Commands

flux check
flux bootstrap github --owner YOUR_ORG --repository YOUR_REPO --branch main --path clusters/dev --personal
flux get kustomizations -A
flux get sources git -A

## Practical Tips

- Keep clusters or environments under dedicated top-level folders.
- Validate Kustomize output locally before pushing.
- Use naming conventions that map clearly to environment and team.
