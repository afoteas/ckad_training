# Readiness and Startup Probes for Databases

Database pods often start slower than stateless APIs. Probes prevent early traffic and restart loops.

## Why These Probes Matter

- readiness avoids routing traffic before DB is usable
- startup gives slow boot databases enough initialization time
- together they reduce failed app-to-db connections during startup

## Probe Roles

- `readinessProbe`: can this pod serve traffic now?
- `startupProbe`: has the app finished booting yet?

If startup probe is configured, readiness/liveness are delayed until startup succeeds.

## Example Pattern

```yaml
readinessProbe:
  exec:
    command: ["mysqladmin", "ping", "-h", "127.0.0.1"]
  initialDelaySeconds: 10
  periodSeconds: 5

startupProbe:
  tcpSocket:
    port: 3306
  periodSeconds: 10
  failureThreshold: 30
```

Interpretation:

- readiness starts after delay and checks DB availability repeatedly
- startup allows up to 300 seconds (`30 * 10s`) for first successful boot

## Operational Guidance

- avoid overly frequent probes (can add DB load)
- tune delays and thresholds to realistic startup times
- validate behavior in staging before production rollout
- watch pod events/logs for probe failures and timing issues

## CKAD Tips

- Know all three probe types: `readinessProbe` (serve traffic?), `livenessProbe` (restart if unhealthy?), and `startupProbe` (finished booting?).
- Each probe supports an `exec`, `httpGet`, or `tcpSocket` handler plus `initialDelaySeconds`, `periodSeconds`, `failureThreshold`, and `timeoutSeconds`.
- A `startupProbe` suspends liveness/readiness until it succeeds; size its budget as `failureThreshold * periodSeconds` for slow databases.
- Add probes by editing the pod template YAML — there is no `kubectl` generator for probes.
- Debug with `kubectl describe pod <name>` (probe failure events) and the pod's restart count from `kubectl get pod`.

## Key Takeaway

Readiness probes keep traffic away from a not-yet-ready database while startup probes give slow-booting databases time before liveness/readiness engage, together preventing dropped connections and restart loops.
