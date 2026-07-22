# Zone-Aware Distribution with Spread Constraints

This lesson demonstrates distributing replicas evenly across simulated availability zones using topology spread constraints — and compares behavior with and without spread rules.

For the theory, see [03-TopologySpreadConstraints](../03-TopologySpreadConstraints/readme.md).

## Demo Overview

1. Start a 3-node Minikube cluster.
2. Label nodes with zone labels to simulate cloud availability zones.
3. Deploy a workload **without** spread constraints and observe distribution.
4. Deploy the same workload **with** spread constraints and verify guaranteed balance.
5. Scale replicas and test uneven counts against `maxSkew`.

## Prerequisites

- Minikube
- `kubectl`
- `jq` (optional, for JSON parsing)

## Step 1: Create a Multi-Node Cluster

```bash
minikube start --nodes=3 --driver=docker
kubectl get nodes
```

This creates one control-plane node (`minikube`) and two worker nodes (`minikube-m02`, `minikube-m03`).

## Step 2: Label Nodes with Zones

Simulate cloud zone labels:

```bash
kubectl label node minikube topology.kubernetes.io/zone=us-east-1a
kubectl label node minikube-m02 topology.kubernetes.io/zone=us-east-1b
kubectl label node minikube-m03 topology.kubernetes.io/zone=us-east-1c
kubectl get nodes -L topology.kubernetes.io/zone
```

In production, cloud providers apply these labels automatically.

## Step 3: Deploy Without Spread Constraints

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-no-spread
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx-no-spread
  template:
    metadata:
      labels:
        app: nginx-no-spread
    spec:
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f deployment-without-spread.yaml
kubectl get pods -l app=nginx-no-spread -o wide
```

Pods may appear distributed, but placement is **not guaranteed**. The default scheduler uses resource availability and affinity — not zone balance.

Count Pods per node:

```bash
kubectl get pods -l app=nginx-no-spread -o json | \
  jq -r '.items[].spec.nodeName' | sort | uniq -c
```

Clean up before the next step:

```bash
kubectl delete -f deployment-without-spread.yaml
```

## Step 4: Deploy With Spread Constraints

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-with-spread
spec:
  replicas: 6
  selector:
    matchLabels:
      app: nginx-with-spread
  template:
    metadata:
      labels:
        app: nginx-with-spread
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: nginx-with-spread
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f deployment-with-spread.yaml
kubectl get pods -l app=nginx-with-spread -o wide
```

With 6 replicas across 3 zones, you get exactly 2 Pods per zone — guaranteed.

## Step 5: Test Scaling

Scale to 9 replicas (evenly divisible by 3):

```bash
kubectl scale deployment nginx-with-spread --replicas=9
```

Result: 3 Pods per zone.

Scale to 7 replicas (not evenly divisible):

```bash
kubectl scale deployment nginx-with-spread --replicas=7
```

Result: distribution like `3-2-2` — uneven but within `maxSkew: 1` (difference of at most 1 between zones).

## Why Spread Matters

Without constraints, a 6-replica app across 3 zones might get `4-2-0` distribution. If the zone with 4 Pods fails, you lose 67% of capacity.

With `maxSkew: 1`, distribution is `2-2-2` or `3-2-2`. A single zone failure loses far less capacity.

## Choosing `maxSkew`

| `maxSkew` | Effect |
|-----------|--------|
| `1` | Strictest balance — zones differ by at most 1 Pod |
| `2` | More flexible — allows larger differences between zones |

Smaller `maxSkew` = more balanced but more `Pending` Pods when capacity is tight.

## Choosing `whenUnsatisfiable`

| Value | Use when |
|-------|----------|
| `DoNotSchedule` | Critical apps — spread is a hard requirement |
| `ScheduleAnyway` | Less critical workloads — best-effort spread is acceptable |

## Useful Commands

```bash
kubectl get pods -l app=nginx-with-spread -o wide
kubectl get pods -l app=nginx-with-spread -o json | \
  jq -r '.items[] | "\(.metadata.name) -> \(.spec.nodeName)"'
kubectl scale deployment nginx-with-spread --replicas=<N>
kubectl get nodes -L topology.kubernetes.io/zone
```

## CKAD Tips

- Be able to write a Deployment with `topologySpreadConstraints` targeting zones.
- Know that `topology.kubernetes.io/zone` requires nodes to be labeled.
- `maxSkew: 1` with 7 replicas across 3 zones gives distributions like `3-2-2`, not `3-3-1`.
- Compare `DoNotSchedule` (hard) vs `ScheduleAnyway` (soft).

## Key Takeaway

Topology spread constraints guarantee even distribution across failure domains. Without them, balanced placement is luck; with them, high availability across zones is enforced at scheduling time.
