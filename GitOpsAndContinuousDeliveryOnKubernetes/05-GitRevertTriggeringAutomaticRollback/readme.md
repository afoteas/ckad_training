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

## Practical Tips

- Prefer revert over force-push to preserve traceability.
- Add incident reference in revert commit message.
- Use protected branches to avoid direct emergency edits.
