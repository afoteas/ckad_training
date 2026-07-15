# Using Startup Probes for Slow Boot Apps

Startup probes prevent premature restarts when applications need extra initialization time.

## Why Startup Probes

Without a startup probe, aggressive liveness checks may kill a healthy but still-booting container, causing CrashLoopBackOff.

When `startupProbe` is present:

1. Kubernetes runs startup probe first.
2. Liveness and readiness are disabled during startup.
3. After startup success, normal probes begin.

## Example

Manifest file: `deployment-with-startup-probes.yaml`

The demo runs a `busybox` container that simulates a slow boot by sleeping 30 seconds
before staying alive. All three probes use a lightweight `exec` check (`cat /dev/null`):

```yaml
# Startup: allows up to 50s (10s x 5) for the container to finish booting.
startupProbe:
  exec:
    command:
      - cat
      - /dev/null
  periodSeconds: 10
  failureThreshold: 5

# Liveness: aggressive (10s tolerance). The startup probe protects it during boot.
livenessProbe:
  exec:
    command:
      - cat
      - /dev/null
  periodSeconds: 5
  failureThreshold: 2

# Readiness: aggressive (10s tolerance) to control Service traffic.
readinessProbe:
  exec:
    command:
      - cat
      - /dev/null
  periodSeconds: 5
  failureThreshold: 2
```

Because the liveness/readiness probes are aggressive (restart/deregister after ~10s),
without the startup probe the 30s boot would trigger a `CrashLoopBackOff`. The startup
probe holds them off for up to 50s, letting the app finish starting.

## Verification

```bash
kubectl apply -f deployment-with-startup-probes.yaml
kubectl get pods -l app=slow-start-app -w
kubectl describe pod -l app=slow-start-app
kubectl logs -l app=slow-start-app --tail=100
```
