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

## CKAD Tips

- Know all three probe types cold: `livenessProbe` restarts the container, `readinessProbe` pulls the pod from Service endpoints, and `startupProbe` gates the other two until boot completes.
- Memorize the handler options `httpGet`, `tcpSocket`, `exec`, and `grpc`, plus the timing fields `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, and `failureThreshold`.
- Add probes fast with `kubectl create deploy web --image=nginx --dry-run=client -o yaml > pod.yaml`, then edit the manifest — there is no imperative flag for probes.
- Use `kubectl describe pod <name>` to read probe failures in the `Events` section (e.g. `Liveness probe failed`) and confirm restart counts.
- Watch out: a too-short `initialDelaySeconds` on a slow app causes `CrashLoopBackOff`; that is the signal to reach for a `startupProbe`.

## Key Takeaway

Kubernetes probes let the kubelet act on container health: liveness restarts dead containers, readiness controls traffic, and startup shields slow-booting apps — pick the right probe and tune its timing to match real application behavior.
