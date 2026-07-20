# Tainting Nodes and Applying Tolerations

This lesson demonstrates how to taint a node and control which Pods are allowed to run on it.

## Demo Files

- `untolerating-pod.yaml`
- `tolerating-pod.yaml`

## Step 1: Taint the Node

```bash
kubectl get nodes
kubectl taint nodes <node-name> dedicated=finance:NoSchedule
kubectl describe node <node-name>
```

Expected behavior: non-tolerating Pods are blocked from scheduling on this node.

## Step 2: Deploy Pod Without Toleration

```bash
kubectl apply -f untolerating-pod.yaml
kubectl get pod untolerating-test -o wide
kubectl describe pod untolerating-test
```

Expected behavior: Pod remains `Pending` if only tainted nodes are available.

## Step 3: Deploy Pod With Matching Toleration

```bash
kubectl apply -f tolerating-pod.yaml
kubectl get pod tolerating-test -o wide
kubectl describe pod tolerating-test
```

Expected behavior: Pod schedules successfully on tainted node.

## Optional Cleanup

```bash
kubectl delete -f untolerating-pod.yaml
kubectl delete -f tolerating-pod.yaml
kubectl taint nodes <node-name> dedicated=finance:NoSchedule-
```

## Key Takeaway

Taints enforce node-level restrictions. Matching tolerations are required for permitted workloads.
