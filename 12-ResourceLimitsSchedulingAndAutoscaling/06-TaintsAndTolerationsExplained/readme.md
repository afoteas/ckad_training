# Taints and Tolerations Explained

Node affinity attracts Pods to nodes. Taints and tolerations do the opposite: they repel Pods unless explicitly allowed.

## Why Use Taints

Use taints to reserve special nodes for specific workloads, such as:

- GPU nodes
- security-sensitive nodes
- infrastructure-only nodes

## Taint Structure

A taint has:

- key
- value
- effect

### Taint Effects

- `NoSchedule`: block new non-tolerating Pods.
- `PreferNoSchedule`: soft avoid behavior.
- `NoExecute`: block new Pods and evict existing non-tolerating Pods.

## Tolerations

A Pod toleration is an allow-list entry in `spec.tolerations`.

To schedule on a tainted node, toleration must match key/value/effect as required by taint logic.

## Operational Value

- Protect expensive hardware from general workloads.
- Isolate critical or system-level services.
- Enforce environment boundaries in shared clusters.

## Key Takeaway

Taints define node restrictions; tolerations grant workload exceptions.
