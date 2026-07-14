# Deploying and Using the metrics-server

metrics-server provides real-time CPU and memory usage metrics for nodes and pods.

## Install

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Verify

```bash
kubectl get deployment metrics-server -n kube-system
```

## Use Metrics API via kubectl top

```bash
kubectl top nodes
kubectl top pods -A
```

## Notes

- metrics-server collects usage from kubelets and exposes Metrics API.
- required for HPA and day-to-day resource troubleshooting.
