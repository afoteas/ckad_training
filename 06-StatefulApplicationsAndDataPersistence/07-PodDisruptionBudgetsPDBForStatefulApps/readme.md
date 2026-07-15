# Pod Disruption Budgets (PDB) for Stateful Apps

PDBs protect availability during planned disruptions such as node drains and upgrades.

## Why PDBs

Stateful apps can break if too many replicas are evicted at once.
A PDB sets how many pods must remain available.

## Voluntary vs Involuntary Disruptions

- voluntary: drain, maintenance, admin eviction, scale actions
- involuntary: node crash, kernel panic, AZ outage

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

## Best Practices

- test PDB behavior in staging
- choose values that balance safety and maintenance speed
- combine with sufficient replica count
- monitor during drains and upgrades
