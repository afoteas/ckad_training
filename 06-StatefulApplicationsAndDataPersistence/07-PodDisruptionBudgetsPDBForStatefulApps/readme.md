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
