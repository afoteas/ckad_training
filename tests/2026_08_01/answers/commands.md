# Imperative / debug log (write commands yourself)

## Q5 — Helm install (release edge-proxy, ns release, 2 replicas)
```
helm install edge-proxy bitnami/nginx --set replicaCount=2 --namespace release
```

## Q6 — Kustomize overlay apply
```
k apply -k answers/kustomize/live
```

## Q7 — checkout-next replica sizing (what counts and why)
```
k get deploy checkout-stable -o yaml > q07.yml # copy checkout-stable so as to edit it
vim q07.yml # edit the confi with new version and replicas and remove autogererated content
k apply -f q07.yml # apply the config
k scale deploy --replicas=2 checkout-stable # scale the stable to as to achieve 33% for the next
```

## Q16 — debug miswired (cause + fix)
```
  Available      False   MinimumReplicasUnavailable
  Progressing    False   ProgressDeadlineExceeded

containerPort8080
readinessProbe.port 9090 -> never ready
also needed to change to exec
```
