# Pod Disruption Budgets (PDB) for Stateful Apps

PDBs protect availability during planned disruptions such as node drains and upgrades.

## Why Pod Disruption Budgets?

- Voluntary disruptions (node drain, upgrades) can evict pods.
- Stateful apps risk downtime if too many pods go offline.
- PDBs define the minimum pods that must stay available.
- They help ensure service continuity during maintenance.

## Voluntary vs Involuntary Disruptions

| Voluntary disruptions | Involuntary disruptions |
| --- | --- |
| Node drains for upgrades | Hardware or VM failures |
| Cluster scaling down | Kernel panics or crashes |
| Admin-initiated pod evictions | Out-of-resource evictions |

PDBs help with voluntary disruptions. They do not stop involuntary failures.

## Core Fields

- `minAvailable`: minimum pods that must stay ready
- `maxUnavailable`: maximum pods allowed to be disrupted
- `selector`: which pods are protected

Example:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mysql-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: mysql
```

With 3 MySQL replicas, this prevents drain/eviction from dropping below 2 available pods.

## Best Practices and Limitations

- always test PDBs in staging before production
- balance resilience and operational flexibility
- combine with higher replica counts for redundancy
- remember that PDBs do not cover involuntary disruptions
- use monitoring to confirm pods remain available

## CKAD Note

- PodDisruptionBudgets are primarily a cluster-operations/CKA topic and are rarely required on CKAD — spend exam prep on the workloads PDBs protect (Deployments, StatefulSets) and their health probes.
- If PDBs do appear, remember the two mutually exclusive fields — `minAvailable` and `maxUnavailable` — plus a `selector`, and that PDBs only guard *voluntary* disruptions (drains, evictions), never node/hardware failures.
- Check status with `kubectl get pdb` and `kubectl describe pdb <name>` (watch `ALLOWED DISRUPTIONS`).

## Key Takeaway

A PDB caps how many matching pods can be voluntarily evicted at once (via `minAvailable`/`maxUnavailable`), protecting stateful availability during drains and upgrades — useful background that sits closer to CKA than core CKAD.
