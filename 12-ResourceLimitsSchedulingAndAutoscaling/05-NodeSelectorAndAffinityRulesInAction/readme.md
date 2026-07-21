# Node Selector and Affinity Rules in Action

This lesson demonstrates practical Pod placement control by labeling nodes and scheduling workloads with `nodeSelector` and `nodeAffinity`.

## Demo Scenario

Label a node as high-performance and schedule targeted workloads onto it.

## Demo Files

- `selector-pod.yaml` – nodeSelector example
- `affinity-required-pod.yaml` – hard nodeAffinity (Pod won't schedule if constraint not met)
- `affinity-preferred-pod.yaml` – soft nodeAffinity with weights (Pod schedules elsewhere if needed)

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

## Step 3: Test Hard nodeAffinity (Required)

Hard affinity (required) prevents scheduling if constraints don't match:

```bash
kubectl apply -f affinity-required-pod.yaml
kubectl get pod affinity-required-pod -o wide
kubectl describe pod affinity-required-pod
```

If no node matches `performance=high`, the Pod stays `Pending`.

## Step 4: Test Soft nodeAffinity (Preferred)

Soft affinity (preferred) guides placement but doesn't block scheduling:

```bash
kubectl apply -f affinity-preferred-pod.yaml
kubectl get pod affinity-preferred-pod -o wide
kubectl describe pod affinity-preferred-pod
```

The scheduler prefers nodes with higher weights:
- Weight 80: `performance=high` (highest priority)
- Weight 20: `disktype=ssd` (lower priority)

If no preferred node exists, Pod still schedules normally on any available node.

### Comparing Required vs Preferred

| Aspect | Required | Preferred |
|--------|----------|-----------|
| No match behavior | Pod stays `Pending` | Pod schedules elsewhere |
| Use case | Hard constraints (must run on specific hardware) | Soft preferences (nice-to-have placement) |
| Weights | Not used | 1-100 priority scoring |

## Key Takeaway

Labeling plus selector/affinity rules gives you deterministic workload placement for performance, cost, and compliance goals.
