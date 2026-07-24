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

## CKAD Note

GitOps as an operating model (pull-based controllers, reconciliation loops, drift self-healing) is **not** part of the CKAD exam — it is real-world platform tooling.

- Examinable foundations underneath GitOps: writing declarative manifests and applying them with `kubectl apply -f`, previewing changes with `kubectl diff -f` and `kubectl apply --dry-run=client`.
- Know how to inspect desired-vs-live differences with `kubectl get -o yaml` and `kubectl describe`, since that is the manual equivalent of reconciliation.
- The GitOps flow (feature branch, PR review, controller sync) is background context; CKAD tests your ability to declaratively define and manage the resources themselves.

## Key Takeaway

GitOps makes Git the single source of truth and lets controllers continuously reconcile the cluster to match it; for CKAD, focus on the underlying declarative-configuration skills (`kubectl apply`, `diff`, `--dry-run`) rather than the GitOps workflow itself.
