# Multi-Environment Promotion Strategies

## Overview

Promotion strategies define how changes move from dev to staging to production in a controlled and auditable way.

## What You Should Know

- Environment isolation can be branch-based, folder-based, or repo-based.
- Promotion should be explicit and policy-governed.
- Tag or commit pinning reduces ambiguity between environments.
- Production should never consume unreviewed mainline changes.

## Common Patterns

- Dev auto-sync from main branch.
- Staging promotion via PR from dev overlays.
- Production promotion via approved PR and pinned image tag.

## Practical Tips

- Use required reviewers for staging and production paths.
- Keep environment differences minimal and intentional.
- Record promotion metadata in PR templates.
- Prefer immutable image tags for production releases.

## CKAD Note

Promotion strategies (branch-/folder-/repo-based environments, PR gates, pinned-image promotion across dev→staging→prod) are a **real-world GitOps process** and are not part of the CKAD exam.

- The in-scope building block is Kustomize overlays: expressing per-environment differences (replicas, images, config) with `overlays/dev`, `overlays/staging`, `overlays/prod` on a shared `base/`, applied via `kubectl apply -k`.
- "Immutable image tags" reflects the exam-relevant habit of pinning explicit `image:` tags/digests instead of `:latest` in your manifests.
- Per-environment isolation on the exam is usually just separate namespaces (`kubectl create namespace`, `-n <env>`), not multi-repo/branch machinery.

## Key Takeaway

Multi-environment promotion is about moving changes through dev/staging/prod with review and pinned tags; for CKAD the transferable pieces are Kustomize overlays per environment, explicit image tags, and namespace separation — the promotion workflow itself is out of scope.
