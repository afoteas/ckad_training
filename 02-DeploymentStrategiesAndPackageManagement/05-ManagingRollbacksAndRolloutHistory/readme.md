# Managing Rollbacks and Rollout History

This lesson covers rollout history inspection and rollback operations for Kubernetes Deployments.

## Why It Matters

Releases can fail after deployment. Fast rollback minimizes outage duration and user impact.

## Core Commands

```bash
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=<n>
```

## Practical Rollback Flow

1. Detect issue in current rollout.
2. Confirm rollout status and events.
3. Inspect revision history.
4. Undo to previous stable revision.
5. Verify recovery and service health.

## Verification

```bash
kubectl get pods -l app=<name>
kubectl describe deployment <name>
```

## Summary

Rollback readiness and revision visibility are mandatory operational controls for safe Kubernetes delivery.

## Transcript Enhancements (Preserved Notes Kept)

### Why Rollout History Matters

Every deployment template change creates a new revision, giving operators an audit trail for:

1. what changed
2. when it changed
3. what to roll back to

### Inspection Patterns

```bash
kubectl rollout history deployment/myapp
kubectl rollout history deployment/myapp --revision=2
```

Use revision inspection to identify problematic image tags or config deltas before triggering rollback.

### Safety Best Practices

- use immutable image tags, not latest
- gate rollout completion on health and metrics
- include rollback logic in CI/CD automation
- document rollback cause to prevent repeat incidents

## CKAD Tips

- Memorize the command set: `kubectl rollout status|history|undo deployment/<name>` plus `--to-revision=<n>`.
- `kubectl rollout undo deploy <name>` reverts to the previous revision; add `--to-revision=<n>` to target a specific one.
- Inspect a single revision's pod template with `kubectl rollout history deploy <name> --revision=<n>`.
- The CHANGE-CAUSE column is populated from the `kubernetes.io/change-cause` annotation — set it to make history readable.
- Use immutable image tags (never `latest`) so each revision is distinct and rollbacks are predictable.

## Key Takeaway

Every Deployment template change creates a new revision, and `kubectl rollout history`/`undo` let you inspect that audit trail and instantly revert to a known-good state.
