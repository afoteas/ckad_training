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
