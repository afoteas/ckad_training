# Imperative / live commands log

Record the exact commands you run for tasks that aren't pure manifests.

## Q2 — rollout strategy + image update + change-cause
```
# strategy edit, then:
# kubectl -n exam-web set image ... --record   (or annotate change-cause)
```

## Q9 — debug Pending pod
```
# diagnosis (describe/events):

# cause:

# fix applied:
```

## Q12 — label node + verify pinned pod
```
# kubectl label node <node> disktype=ssd
```

## Any other live commands
```
```
