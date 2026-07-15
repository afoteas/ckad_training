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
