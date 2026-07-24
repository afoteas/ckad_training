# Implementing Readiness and Liveness Probes

This lesson demonstrates adding readiness and liveness checks to a Deployment to avoid routing traffic to unready pods and to recover from deadlocked containers.

## Behavior Summary

- liveness failure: container restarted
- readiness failure: pod stays running but is removed from Service load-balancing

## Example Structure

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 15
  periodSeconds: 20
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 15
  periodSeconds: 20
  timeoutSeconds: 5
  failureThreshold: 3
```

## Apply and Verify

```bash
kubectl apply -f deployment.yaml
kubectl get pods
kubectl describe pod <pod-name>
```

Use distinct readiness and liveness endpoints when your app can be alive before it is truly ready to handle traffic.

## How to Run (This Lesson)

From this folder:

```bash
kubectl apply -f deployment-with-probes.yaml
kubectl get pods -l app=health-check-app -w
```

Inspect probe behavior:

```bash
kubectl describe pod -l app=health-check-app
kubectl logs -l app=health-check-app --tail=100
```

Cleanup:

```bash
kubectl delete -f deployment-with-probes.yaml
```

## CKAD Tips

- Both `livenessProbe` and `readinessProbe` are nested under `spec.containers[].` — indentation errors here are a common exam mistake.
- Remember the behavior difference: a failed liveness probe **restarts** the container, while a failed readiness probe only **removes the pod from Service load-balancing** (no restart).
- Use distinct endpoints when an app can be alive before it is ready — a shared `/` path for both probes can mask real readiness problems.
- Verify quickly with `kubectl get pods` (watch `READY` column) and `kubectl describe pod <name>` to see probe events; `kubectl logs -l <selector>` confirms the app is actually serving.
- Tune `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, and `failureThreshold` to the real app; defaults are often too aggressive.

## Key Takeaway

Adding readiness and liveness probes to a Deployment keeps traffic off unready pods and auto-recovers deadlocked containers — the core reliability pattern the CKAD expects you to configure by hand in a manifest.
