# Imperative / debug log (write commands yourself)

## Q5 — Helm upgrade (portal → 4 replicas, nginx:1.27)
```
helm install portal ../localchart --set image=nginx:1.27,replicaCount=4 -n release
```

## Q6 — Helm rollback (portal to previous revision)
```
helm rollback portal -n release  
```

## Q7 — Blue/green cutover (shop-blue → shop-green)
```

```

## Q16 — debug blocked pod (cause + fix)
```

```
