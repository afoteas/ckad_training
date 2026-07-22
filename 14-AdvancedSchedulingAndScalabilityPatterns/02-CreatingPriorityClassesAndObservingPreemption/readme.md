# Creating PriorityClasses and Observing Preemption

This lesson walks through defining PriorityClasses, deploying Pods with different priorities, and watching the scheduler preempt lower-priority Pods under resource pressure.

For the theory behind PriorityClasses and preemption, see [01-PriorityClassesAndPreemptionExplained](../01-PriorityClassesAndPreemptionExplained/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `priority-classes.yaml` | `high-priority` (`value: 1000`) and `low-priority` (`value: 100`) classes |
| `low-priority-pods.yaml` | 9 Pods requesting `1100m` CPU each, all using `low-priority` |
| `high-priority-pod.yaml` | Single Pod requesting `1000m` CPU using `high-priority` — triggers preemption |

## Demo Overview

1. Start a resource-constrained Minikube cluster (2 CPUs).
2. Apply PriorityClasses and verify them.
3. Deploy low-priority Pods that consume nearly all CPU.
4. Deploy a high-priority Pod and watch a low-priority Pod get evicted.
5. Inspect preemption events and Pod priority details.

## Prerequisites

- Docker (or compatible container runtime)
- `kubectl`
- Minikube

## Step 1: Start a Constrained Cluster

```bash
minikube start --cpus=2 --memory=1800 --driver=docker
kubectl cluster-info
kubectl get nodes
```

A small cluster makes resource contention easy to observe.

## Step 2: Create PriorityClasses

```bash
kubectl apply -f priority-classes.yaml
kubectl get priorityclasses
```

Expected output includes your classes plus built-in ones:

```text
NAME                      VALUE        GLOBAL-DEFAULT   AGE
high-priority             1000         false            ...
low-priority              100          false            ...
system-cluster-critical   2000000000   false            ...
system-node-critical      2000001000   false            ...
```

### `priority-classes.yaml` breakdown

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High-priority workloads"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "Low-priority workloads"
```

Neither class sets `preemptionPolicy`, so both default to `PreemptLowerPriority`.

## Step 3: Deploy Low-Priority Pods

```bash
kubectl apply -f low-priority-pods.yaml
kubectl get pods -w
```

Each Pod in `low-priority-pods.yaml` sets `priorityClassName: low-priority` and requests `1100m` CPU. With only 2 CPUs available, 8 Pods typically start and 1 stays `Pending`.

Check how much CPU is allocated:

```bash
kubectl describe node minikube | grep -A 10 "Allocated resources"
```

You should see CPU requests near capacity (~95%).

## Step 4: Deploy a High-Priority Pod

```bash
kubectl apply -f high-priority-pod.yaml
kubectl get pods -w
```

`high-priority-pod.yaml` requests `1000m` CPU with `priorityClassName: high-priority`. The cluster has only ~`100m`–`200m` CPU left, so the scheduler preempts one or more low-priority Pods to free enough capacity.

Watch for a low-priority Pod disappearing (for example `low-priority-pod-7`) while `high-priority-pod` moves to `Running`.

## Step 5: Verify Preemption

```bash
kubectl get events --sort-by='.lastTimestamp' | grep -i preempt
kubectl describe pod high-priority-pod | grep -i priority
```

Expected details on the high-priority Pod:

```text
Priority:         1000
Priority Class Name:  high-priority
```

Preemption events show which low-priority Pod was evicted and why scheduling failed before preemption.

Inspect priority across all demo Pods:

```bash
kubectl get pods -o custom-columns=\
NAME:.metadata.name,\
PRIORITY:.spec.priority,\
CLASS:.spec.priorityClassName,\
STATUS:.status.phase
```

## Why One Eviction Is Enough

Rough math for this demo:

- Node has ~`2000m` total CPU; system Pods reserve ~`750m`.
- 8 low-priority Pods × `1100m` ≈ `8800m` requested (scheduler fits as many as possible).
- ~`100m`–`200m` remains free.
- High-priority Pod needs `1000m` → scheduler must evict at least one low-priority Pod (`1100m` freed).

The scheduler evicts the minimum number of lower-priority Pods needed, respecting PDBs when present.

## Cleanup

```bash
kubectl delete -f high-priority-pod.yaml
kubectl delete -f low-priority-pods.yaml
kubectl delete -f priority-classes.yaml
```

## Useful Commands

```bash
kubectl get priorityclasses
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,CLASS:.spec.priorityClassName
kubectl get events --sort-by='.lastTimestamp'
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

## CKAD Tips

- Be able to write a `PriorityClass` manifest and a Pod with `priorityClassName`.
- Higher `value` = higher priority; default is `0` for Pods without a class.
- Preemption evicts lower-priority Pods when a higher-priority Pod cannot be scheduled.
- `preemptionPolicy: Never` gives queue priority without eviction.

## Key Takeaway

Under resource pressure, Kubernetes automatically evicts lower-priority Pods to schedule higher-priority ones. Define a clear priority hierarchy and test it with realistic resource requests.
