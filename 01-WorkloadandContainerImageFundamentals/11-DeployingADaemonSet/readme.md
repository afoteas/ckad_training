# Deploying a DaemonSet

A **DaemonSet** ensures one Pod runs on **every eligible node** (or a subset via `nodeSelector` / affinity). Use it for node-level agents: log collectors, monitoring exporters, CNI plugins.

For workload-type theory, see [04-ChooseTheRightWorkloadResources](../04-ChooseTheRightWorkloadResources/readme.md).

## Demo File

- `daemonset.yaml` — simple `node-logger` DaemonSet that prints the node hostname every 30 seconds

## Deploy and Verify

```bash
kubectl apply -f daemonset.yaml
kubectl get daemonset node-logger
kubectl get pods -l app=node-logger -o wide
```

You should see **one Pod per node**, each scheduled on a different `NODE`.

```bash
kubectl logs -l app=node-logger --prefix=true --tail=3
```

Each line shows a different hostname (the node name).

## DaemonSet vs Deployment

| | Deployment | DaemonSet |
|--|------------|-----------|
| Replica count | You set `replicas` | One per node (automatic) |
| Use case | Stateless apps | Per-node agents |
| Scaling | Horizontal by replica count | Scales when nodes join/leave |

## Optional: Limit to Specific Nodes

Add a `nodeSelector` or `nodeAffinity` in the Pod template to run only on nodes with a given label (e.g. `logging=enabled`).

## CKAD Tips

- DaemonSet has `spec.selector` + template labels — same rules as Deployment.
- `kubectl get ds` is shorthand for DaemonSet.
- On exam: if the task says "one Pod on every node", use DaemonSet, not a Deployment with high `replicas`.

## Cleanup

```bash
kubectl delete -f daemonset.yaml
```

## Key Takeaway

DaemonSet = one Pod per node. Deploy it when the workload must run on every (or selected) node, not when you need N identical replicas regardless of node count.
