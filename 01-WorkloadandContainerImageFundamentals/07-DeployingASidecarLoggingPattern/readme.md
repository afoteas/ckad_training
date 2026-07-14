# Deploying a Sidecar Logging Pattern

This lesson demonstrates the sidecar logging pattern, where a dedicated helper container collects and forwards logs from the main application container.

## Why Use a Logging Sidecar

The main app should focus on business logic, not shipping logs to external systems. A sidecar container handles log collection separately.

Benefits:

- separation of concerns
- reusable logging agent logic
- independent updates for log pipeline behavior

## Pattern Architecture

Inside one Pod:

1. main app writes logs to a shared volume
2. sidecar tails the same file from shared volume
3. sidecar forwards entries to external logging backend

Shared bridge is typically an `emptyDir` mounted in both containers.

## Apply the Demo

```bash
kubectl apply -f sidecar-deployment.yaml
kubectl rollout status deployment/logging-sidecar-demo
kubectl get pods -l app=sidecar-demo
```

## Verify Log Flow

```bash
kubectl logs deployment/logging-sidecar-demo -c log-collector --tail=20
kubectl logs deployment/logging-sidecar-demo -c main-app --tail=20
```

Both outputs should show coordinated activity through the shared log file path.

## Common Failure and Fix

One observed failure in this demo was:

```text
exec: "/usr/bin/tail": stat /usr/bin/tail: no such file or directory
```

Cause: BusyBox image does not provide `tail` at `/usr/bin/tail`.

Safe fix used:

```yaml
command: ["/bin/sh", "-c"]
args: ["touch /mnt/logs/app.log && tail -f /mnt/logs/app.log"]
```

## Debug Commands

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c log-collector --previous
```

## Summary

The sidecar logging pattern is a practical Kubernetes design for centralized log collection without embedding operational logging logic directly in application code.