# Deploying and Using the metrics-server

metrics-server provides real-time CPU and memory usage metrics for nodes and pods.

## Install

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Install on Minikube

If you are using Minikube, the simplest way is enabling the built-in addon:

```bash
minikube addons enable metrics-server
```

If you use a non-default profile:

```bash
minikube -p mini-ckad addons enable metrics-server
```

## Verify

```bash
kubectl get deployment metrics-server -n kube-system
kubectl get apiservices | grep metrics.k8s.io
```

## Use Metrics API via kubectl top

```bash
kubectl top nodes
kubectl top pods -A
```

## Notes

- metrics-server collects usage from kubelets and exposes Metrics API.
- required for HPA and day-to-day resource troubleshooting.
