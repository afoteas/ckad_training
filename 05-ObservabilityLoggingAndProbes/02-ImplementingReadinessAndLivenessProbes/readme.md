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
