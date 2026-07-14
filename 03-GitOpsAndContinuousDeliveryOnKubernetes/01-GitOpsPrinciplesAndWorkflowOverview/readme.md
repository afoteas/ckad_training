# GitOps Principles and Workflow Overview

## Overview

GitOps is an operating model where Git is the single source of truth for both application and infrastructure configuration. Controllers in the cluster continuously compare desired state from Git with actual cluster state and reconcile differences.

## What You Should Know

- Declarative configuration is mandatory. Store manifests, Helm values, and Kustomize overlays in Git.
- Pull-based delivery is safer than push-based CI deploys because the cluster fetches and applies changes itself.
- Reconciliation loops make drift visible and usually self-healing.
- Every change should be traceable to a commit, PR review, and audit trail.

## Typical GitOps Flow

1. Developer updates manifests in a feature branch.
2. Pull request is reviewed and merged.
3. GitOps controller detects new commit.
4. Controller applies changes to the cluster.
5. Health and sync status are reported.

## Practical Tips

- Keep apps and platform configs separated in folders or repos.
- Use small PRs to reduce rollback complexity.
- Protect main branch with required reviews and checks.
- Tag releases so environment promotion is reproducible.

## Quick Lab Ideas

- Intentionally change a replica count in-cluster and observe auto-reconciliation.
- Compare last synced revision with current live resources.
