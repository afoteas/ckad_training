# Node Selector and Affinity Rules in Action

This lesson demonstrates practical Pod placement control by labeling nodes and scheduling workloads with `nodeSelector` and `nodeAffinity`.

## Demo Scenario

Label a node as high-performance and schedule targeted workloads onto it.

## Demo Files

- `selector-pod.yaml`
- `affinity-pod.yaml`

## Step 1: Label a Node

```bash
kubectl get nodes
kubectl label node <node-name> performance=high
kubectl get node <node-name> --show-labels
```

## Step 2: Test nodeSelector

```bash
kubectl apply -f selector-pod.yaml
kubectl get pod selector-test-pod -o wide
```

If selector matches `performance=high`, Pod schedules.

If you change selector to `performance=low` and no node matches, Pod stays `Pending`.

## Step 3: Test nodeAffinity

Use `requiredDuringSchedulingIgnoredDuringExecution` for hard placement behavior similar to `nodeSelector`.

Use `preferredDuringSchedulingIgnoredDuringExecution` for soft preference behavior.

```bash
kubectl apply -f affinity-pod.yaml
kubectl get pod affinity-test-pod -o wide
kubectl describe pod affinity-test-pod
```

## Key Takeaway

Labeling plus selector/affinity rules gives you deterministic workload placement for performance, cost, and compliance goals.
