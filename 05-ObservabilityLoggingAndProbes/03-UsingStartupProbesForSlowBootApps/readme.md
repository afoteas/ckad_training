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

## CKAD Tips

- A `startupProbe` disables the liveness and readiness probes until it succeeds, so slow-booting apps avoid premature restarts.
- Size the startup budget with `periodSeconds * failureThreshold` (here `10 * 5 = 50s`) — it must exceed the app's worst-case boot time.
- The classic symptom a startup probe fixes is a healthy app stuck in `CrashLoopBackOff` because an aggressive `livenessProbe` kills it mid-boot.
- `exec` handlers run inside the container (e.g. `cat /dev/null`); confirm the binary exists in the image or the probe fails instantly.
- Inspect the ordering in `kubectl describe pod` — you'll see startup probe events precede liveness/readiness activity.

## Key Takeaway

Startup probes give slow-booting containers a protected startup window, letting you keep liveness and readiness checks aggressive without triggering false-positive restarts.
