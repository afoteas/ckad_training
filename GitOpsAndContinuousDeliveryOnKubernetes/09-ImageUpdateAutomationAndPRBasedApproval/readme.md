# Image Update Automation and PR-Based Approval

## Overview

Image automation detects new container image versions and proposes updates as pull requests so humans can review before deployment to sensitive environments.

## What You Should Know

- Automation should update manifests, not deploy directly to production.
- PR-based approval keeps compliance and audit requirements intact.
- Version policies can restrict updates to patch or minor streams.
- Rollback remains a simple Git revert.

## Safe Automation Model

1. Registry gets new image tag.
2. Automation tool creates PR with manifest update.
3. CI validates manifests and tests.
4. Reviewer approves and merges.
5. GitOps controller syncs merged change.

## Practical Tips

- Use semantic version filters where possible.
- Block mutable tags like latest in production.
- Require status checks before merge.
- Include changelog or release notes in automated PR body.
