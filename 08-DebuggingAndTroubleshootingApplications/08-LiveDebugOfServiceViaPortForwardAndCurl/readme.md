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