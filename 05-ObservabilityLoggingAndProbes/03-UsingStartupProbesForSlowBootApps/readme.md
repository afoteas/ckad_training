# Using Startup Probes for Slow Boot Apps

Startup probes prevent premature restarts when applications need extra initialization time.

## Why Startup Probes

Without a startup probe, aggressive liveness checks may kill a healthy but still-booting container, causing CrashLoopBackOff.

When `startupProbe` is present:

1. Kubernetes runs startup probe first.
2. Liveness and readiness are disabled during startup.
3. After startup success, normal probes begin.

## Example

```yaml
startupProbe:
  exec:
    command: ["cat", "/tmp/app-ready"]
  periodSeconds: 10
  failureThreshold: 5

livenessProbe:
  exec:
    command: ["cat", "/tmp/app-ready"]
  periodSeconds: 5
  failureThreshold: 2
```

This allows up to 50 seconds of startup grace before restart logic triggers.

## Verification

```bash
kubectl apply -f startup-probe-demo.yaml
kubectl get pods
kubectl describe pod <pod-name>
```
