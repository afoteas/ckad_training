# Kubernetes Probes

Kubernetes probes are periodic checks run by kubelet to determine container health and traffic readiness.

## Probe Types

- `livenessProbe`: checks if app is alive; failure triggers container restart.
- `readinessProbe`: checks if app can serve traffic; failure removes pod from Service endpoints.
- `startupProbe`: protects slow boot apps by disabling liveness/readiness checks until startup succeeds.

## Supported Probe Methods

- `httpGet`
- `tcpSocket`
- `exec`
- `grpc`

## Key Timing Controls

- `initialDelaySeconds`
- `periodSeconds`
- `timeoutSeconds`
- `failureThreshold`

## Best Practices

1. Keep probe endpoints lightweight and fast.
2. Use both liveness and readiness for robust reliability.
3. Tune timings to real application startup and runtime behavior.
4. Validate probe settings in non-production before rollout.

## Basic Combined Example (All 3 Probes)

Manifest file: `probe-demo.yaml`

Quick test:

```bash
kubectl apply -f probe-demo.yaml
kubectl get pods -l app=probe-demo -w
kubectl describe pod -l app=probe-demo
```
