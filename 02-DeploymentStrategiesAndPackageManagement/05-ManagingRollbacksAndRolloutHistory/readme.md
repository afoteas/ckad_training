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
