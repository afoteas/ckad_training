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

## CKAD Tips

- `kubectl top nodes` and `kubectl top pods` (add `-A`, `-n <ns>`, or `--containers`) are the exam-relevant commands — they only work once metrics-server (or the Minikube addon) is running.
- If `kubectl top` returns `error: Metrics API not available`, metrics-server isn't ready yet; verify with `kubectl get deployment metrics-server -n kube-system` and `kubectl get apiservices | grep metrics.k8s.io`.
- Metrics feed the Horizontal Pod Autoscaler, so `kubectl autoscale` and CPU-based HPA depend on this component being installed.
- Installing/patching metrics-server (e.g. `--kubelet-insecure-tls` on dev clusters) is real-world setup; on the exam the cluster is typically pre-provisioned, so focus on *using* `kubectl top`.

## Key Takeaway

metrics-server exposes live CPU/memory usage through the Metrics API, powering both `kubectl top` for troubleshooting and the HPA for autoscaling — know the `kubectl top` commands and how to confirm the API is available.
