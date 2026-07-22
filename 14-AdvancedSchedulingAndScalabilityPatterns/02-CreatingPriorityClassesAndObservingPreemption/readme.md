# Creating PriorityClasses and Observing Preemption

This lesson walks through defining high- and low-priority classes, deploying Pods under resource pressure, and watching the scheduler preempt lower-priority Pods to make room for critical workloads.

For the theory behind PriorityClasses, see [01-PriorityClassesAndPreemptionExplained](../01-PriorityClassesAndPreemptionExplained/readme.md).

## Demo Overview

The demonstration uses a resource-constrained Minikube cluster to show preemption in action:

1. Create `high-priority` and `low-priority` PriorityClasses.
2. Deploy 9 low-priority Pods that consume nearly all available CPU.
3. Deploy 1 high-priority Pod that triggers eviction of a low-priority Pod.

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

A small cluster (2 CPUs, 1800 MiB memory) makes resource contention easy to observe.

## Step 2: Create PriorityClasses

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

Apply and verify:

```bash
kubectl apply -f priority-classes.yaml
kubectl get priorityclasses
```

You will also see built-in system classes like `system-node-critical` and `system-cluster-critical`.

## Step 3: Deploy Low-Priority Pods

Deploy multiple low-priority Pods, each requesting significant CPU (for example `1100m`):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: low-priority-pod-1
spec:
  priorityClassName: low-priority
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "1100m"
        memory: "128Mi"
```

Repeat for 9 Pods. With 2 CPUs available, most start running but one remains `Pending` because total requests exceed capacity.

Check node allocation:

```bash
kubectl describe node minikube | grep -A 10 "Allocated resources"
```

## Step 4: Deploy a High-Priority Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: high-priority-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "1000m"
        memory: "128Mi"
```

```bash
kubectl apply -f high-priority-pod.yaml
kubectl get pods -w
```

The scheduler preempts one or more low-priority Pods to free CPU, then schedules the high-priority Pod.

## Step 5: Verify Preemption Events

```bash
kubectl get events --sort-by='.lastTimestamp' | grep -i preempt
kubectl describe pod high-priority-pod | grep -i priority
```

Expected output shows:

- `priority: 1000`
- `Priority Class Name: high-priority`
- Preemption events for evicted low-priority Pods

## How the Scheduler Chooses Victims

When preemption is required, the scheduler:

1. Identifies lower-priority Pods that, if removed, free enough resources.
2. Considers PodDisruptionBudgets and application availability requirements.
3. Evicts the minimum number of Pods needed.

In the demo, evicting one low-priority Pod (requesting `1100m`) frees enough CPU for the high-priority Pod (requesting `1000m`).

## Real-World Use Cases

| Scenario | How preemption helps |
|----------|---------------------|
| Data processing | Critical real-time analytics preempt background ETL jobs |
| Microservices | Core billing service preempts optional feature Pods |
| Batch workloads | Production services preempt restartable batch jobs |

## Useful Commands

```bash
kubectl get priorityclasses
kubectl get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,CLASS:.spec.priorityClassName
kubectl get events --sort-by='.lastTimestamp'
kubectl describe node <node-name> | grep -A 10 "Allocated resources"
```

## CKAD Tips

- Be able to write both `PriorityClass` and Pod manifests with `priorityClassName`.
- Higher `value` = higher priority; default is `0` for Pods without a class.
- Preemption evicts lower-priority Pods when a high-priority Pod cannot be scheduled.

## Key Takeaway

Under resource pressure, Kubernetes automatically evicts lower-priority Pods to schedule higher-priority ones. Define a clear priority hierarchy and use it for workloads with genuinely different importance levels.
