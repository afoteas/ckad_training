# Live Debug of Service via Port-forward and cURL

This lesson walks through diagnosing a broken service path by forwarding ports and validating responses incrementally.

## Goal

Detect mismatch between Service port mapping and container listening port.

## Workflow

Deploy app and service:

```bash
kubectl apply -f broken-app.yaml
kubectl get deployments
kubectl get pods
kubectl get services
```

Forward to service and test:

```bash
kubectl port-forward svc/webapp-service 8080:80
curl localhost:8080
```

If response fails, inspect pod details:

```bash
kubectl get pods -l app=webapp
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].ports[0].containerPort}'
```

Forward to pod with correct port:

```bash
kubectl port-forward pod/<pod-name> 8080:8080
curl localhost:8080
```

Expected result: successful response confirms app works and service mapping is the issue.

## Root Cause Pattern

- service targets port 80
- container actually listens on 8080
- fix by updating service/targetPort mapping and reapplying manifests

## CKAD Tips

- Isolate the layer by forwarding to each independently: `kubectl port-forward svc/<name> ...` vs `kubectl port-forward pod/<name> ...` — if the pod works but the service doesn't, the Service mapping is broken.
- The usual culprit is a `targetPort` (Service) that doesn't match the container's `containerPort`; `port` is what the Service listens on, `targetPort` is where it forwards.
- Read the actual container port fast with `kubectl get pod <pod> -o jsonpath='{.spec.containers[0].ports[0].containerPort}'`.
- Confirm the Service selected any pods with `kubectl get endpoints <service>` — an empty endpoints list means a label/selector mismatch, not a port issue.
- Pair `port-forward` with `curl localhost:<port>` to validate responses incrementally as you move from service to pod.

## Key Takeaway

When a service path is broken, port-forward to the pod and to the service separately: a working pod plus a failing service points to a `port`/`targetPort` (or selector) mismatch you can fix in the Service manifest.