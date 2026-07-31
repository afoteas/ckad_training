# Imperative / live commands log

Record the exact commands you run for non-manifest tasks (write them yourself).

## Q5 — Helm install (release shopfront, ns deploy, replicaCount=2)
```
helm install shopfront bitnami/nginx --namespace deploy --set replicaCount=2
```

## Q6 — Kustomize overlay apply
```
k apply -k kustomize/overlay/ -n deploy
```

## Q7 — rolling update to nginx:1.26 + change-cause, then rollback to nginx:1.24
```
k set image deploy web-app nginx=nginx:1.26 -n deploy
k annotate deploy web-app -n deploy kubernetes.io/change-cause="image updated to 1.26"
k rollout undo deploy web-app -n deploy
```

## Q16 — debug 'flaky' (diagnosis, cause, fix)
```
readiness Port was different that the containerPort.. changed both to 80
```

## Any other live commands
```

```
