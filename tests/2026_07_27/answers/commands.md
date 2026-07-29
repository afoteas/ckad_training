# Imperative / live commands log

Record here any commands you ran that are NOT captured in a qNN.yaml file
(rollouts, rollbacks, scaling, labeling, kubectl set, fixes to broken-app, etc.).
Label each block with its task number so scoring can follow.

## Q2 — rolling update + rollback

kubectl set image deployments/frontend -n ckad-web nginx=nginx:1.27
kubectl rollout status deployment/frontend -n ckad-web 
kubectl rollout undo  deployment/frontend -n ckad-web
kubectl rollout history deploy/frontend -n ckad-web

## Q9 — fix broken-app
kubectl get deploy broken-app -n ckad-health -o yaml
kubectl patch deploy broken-app -n ckad-health --patch '{"spec":{"template":{"spec":{"containers":[{"name":"web", "image":"nginx:1.25"}]}}}}'
kubectl edit deploy broken-app -n ckad-health
kubectl rollout restart deploy broken-app -n ckad-health

## (other imperative commands)

