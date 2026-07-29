# Imperative / live commands log

Record here any commands you ran that are NOT captured in a qNN.yaml file
(scaling, rollouts, rollbacks, kubectl set, fixes to crashy/resource-app, etc.).
Label each block with its task number so scoring can follow.

## Q1 — scale to 5
k patch deploy api -p '{"spec":{"replicas":5}}'


## Q2 — rollout change-cause + rollback

k set image deployment/api nginx=nginx:1.27
kubectl annotate deployment/api kubernetes.io/change-cause="image updated to 1.27"
k rollout undo deploy api
kubectl annotate deployment/api kubernetes.io/change-cause="rollback to 1.25"
k rollout history deploy api

## Q7 — set resources on resource-app
k set resources deploy resource-app --requests=cpu=100m,memory=128Mi --limits=cpu=300m,memory=256Mi

## Q9 — fix crashy
sleeep should be sleep
fixed with:
k edit deploy crashy
## (other imperative commands)

