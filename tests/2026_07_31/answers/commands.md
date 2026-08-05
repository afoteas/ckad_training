# Imperative / debug log (write commands yourself)

## Q5 — Helm install (release webtier, ns deploy, 3 replicas)
```
helm install webtier bitnami/apache --set replicaCount=3 --namespace deploy
```

## Q6 — Kustomize overlay apply
```
k apply -k kustomize/prod
```

## Q7 — canary sizing (what replica counts and why)
```
v1 has 3 so v2 must have 1 so 1 is the 25% of 4
I copyed the v1
k get deploy payment-v1 -o yaml > q07.yaml
and edited the fields and deployed
k apply -f q07.yaml
```

## Q16 — debug broken-cfg (cause + fix)
```
config map is missing
k create configmap app-settings -n observe --from-literal=SETTING_A=peos
```
