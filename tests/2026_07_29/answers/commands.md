# Imperative / live commands log

Record the exact commands you run for tasks that aren't pure manifests.

## Q2 — rollout strategy + image update + change-cause
```

k patch deploy store -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge": 2, "maxUnavailable": 0}}}}'
k -n exam-web set image deploy store nginx=nginx:1.27
k annotate deploy store kubernetes.io/change-cause="update nginx to v1.27"
k rollout history deploy store
```

## Q9 — debug Pending pod
```
# diagnosis (describe/events):
i saw with k get deploy stuck -o yaml that it was asking for 300Gi so this was not normal
# cause:
not enough memory at the cluster for pod asking 300Gi

# fix applied:
change resources.memory to 300Mi with commnad 
k edit deploy stuck
```

## Q12 — label node + verify pinned pod
```
# kubectl label node <node> disktype=ssd
```

## Any other live commands
```
```
