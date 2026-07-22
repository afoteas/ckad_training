# Running Descheduler as a CronJob

This lesson installs the descheduler via Helm, configures a `LowNodeUtilization` strategy, and runs it on a nightly CronJob schedule to rebalance workloads across nodes.

For descheduler theory and strategies, see [08-DeschedulerForPostDeploymentRebalancing](../08-DeschedulerForPostDeploymentRebalancing/readme.md).

## Demo Files

- `descheduler-values.yaml` — Helm values with nightly CronJob schedule and `LowNodeUtilization` policy
- `test-workload.yaml` — imbalanced Deployment pinned to the control-plane node

## Demo Overview

1. Create a 3-node Minikube cluster.
2. Add the descheduler Helm repository.
3. Install the descheduler with custom values (low node utilization + CronJob schedule).
4. Deploy an imbalanced workload and manually trigger a descheduler run.
5. Observe Pods redistributed across nodes.

## Prerequisites

- Minikube
- `kubectl`
- Helm

## Step 1: Create a Multi-Node Cluster

```bash
minikube start --nodes=3 --driver=docker
kubectl get nodes
```

## Step 2: Add Descheduler Helm Repository

```bash
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler
helm repo update
```

## Step 3: Configure Descheduler Values

See `descheduler-values.yaml` for the full Helm values file. Key settings:

- `schedule: "0 2 * * *"` — run at 2:00 AM every night
- `LowNodeUtilization` with 20% underutilized and 50% target thresholds

### Threshold Explanation

| Setting | Value | Meaning |
|---------|-------|---------|
| `thresholds` | 20% | Nodes below 20% utilization are underutilized |
| `targetThresholds` | 50% | Goal: keep nodes around 50% after rebalancing |

## Step 4: Install Descheduler

```bash
helm install descheduler descheduler/descheduler \
  --namespace kube-system \
  --values descheduler-values.yaml
```

Verify:

```bash
kubectl get cronjob -n kube-system
kubectl get configmap -n kube-system -l app.kubernetes.io/name=descheduler -o yaml
```

## Step 5: Create an Imbalanced Workload

Deploy Pods pinned to the control-plane node to simulate imbalance:

```bash
kubectl apply -f test-workload.yaml
kubectl get pods -l app=test-workload -o wide
```

All Pods may run on the control-plane node while worker nodes sit empty.

## Step 6: Manually Trigger a Descheduler Run

Instead of waiting until 2 AM:

```bash
kubectl create job --from=cronjob/descheduler descheduler-manual -n kube-system
kubectl get jobs -n kube-system -w
```

After completion, check Pod distribution:

```bash
kubectl get pods -l app=test-workload -o wide
```

Pods should now be spread across `minikube`, `minikube-m02`, and `minikube-m03`.

## Step 7: Review Logs and Events

```bash
kubectl logs -n kube-system -l job-name=descheduler-manual
kubectl get events --sort-by='.lastTimestamp' | grep -i evict
```

Logs show eviction counts. Events show individual Pod evictions from overutilized nodes.

## What Happens During Rebalancing

1. Descheduler measures CPU, memory, and Pod count on each node.
2. It identifies underutilized nodes (below 20%) and overutilized nodes (above 50%).
3. It evicts Pods from overutilized nodes.
4. The Kubernetes scheduler reschedules evicted Pods onto underutilized nodes.

## Scheduler vs Descheduler

| | Scheduler | Descheduler |
|---|-----------|-------------|
| When | Pod creation | Periodic (CronJob) |
| Action | Places new Pods | Evicts misplaced Pods |
| Goal | Initial placement | Corrective rebalancing |

## Real-World Benefits

| Benefit | Detail |
|---------|--------|
| Cost savings | Better utilization means fewer wasted nodes; enables scale-down |
| Performance | Prevents resource exhaustion on hot nodes |
| Availability | Spreads load so one node failure has less impact |
| Automation | Runs nightly without manual intervention |

## Useful Commands

```bash
helm install descheduler descheduler/descheduler -n kube-system --values descheduler-values.yaml
kubectl get cronjob -n kube-system
kubectl create job --from=cronjob/descheduler descheduler-manual -n kube-system
kubectl logs -n kube-system -l job-name=descheduler-manual
kubectl get events --sort-by='.lastTimestamp' | grep -i evict
```

## CKAD Note

Descheduler installation and CronJob configuration are beyond CKAD scope. Know conceptually that it rebalances Pods after initial scheduling using strategies like `LowNodeUtilization`.

## Key Takeaway

Deploy the descheduler as a CronJob to automatically rebalance imbalanced clusters. Configure thresholds conservatively, protect critical workloads with PDBs, and verify the impact before running in production.
