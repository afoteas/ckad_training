# Deploying a MySQL StatefulSet with volumeClaimTemplates

This lesson demonstrates automatic per-pod persistent storage provisioning with StatefulSets.

## Resources in the Manifest

A typical manifest includes:

1. Headless Service (`clusterIP: None`) for stable pod DNS
2. StatefulSet with:
- `serviceName` pointing to the headless service
- `replicas` (for example 3 gives `mysql-0`, `mysql-1`, `mysql-2`)
- matching `selector` and pod-template `labels`
- `volumeClaimTemplates` to auto-create one PVC per pod

## Why volumeClaimTemplates

`volumeClaimTemplates` tells Kubernetes to create a unique PVC for each pod identity.

Example pattern:

- `www-web-0`
- `www-web-1`

Each PVC is bound to its corresponding pod ordinal identity and reattached on restart.

## How to Run

Manifest file in this lesson:

- `statefulset-headless-nginx.yaml`

```bash
kubectl apply -f statefulset-headless-nginx.yaml
kubectl get svc nginx
kubectl get statefulset web
kubectl get pods -l app=nginx
kubectl get pvc
kubectl get pv
```

## Persistence Verification Flow

1. Write data in `web-0`
2. Delete pod `web-0`
3. Wait for recreated `web-0`
4. Read file again and confirm data still exists

Example commands:

```bash
kubectl exec web-0 -- sh -c 'echo "Data persisted at $(date)" > /usr/share/nginx/html/test.txt'
kubectl exec web-0 -- cat /usr/share/nginx/html/test.txt
kubectl delete pod web-0
kubectl get pods -l app=nginx -w
kubectl exec web-0 -- cat /usr/share/nginx/html/test.txt
```

If the text is still present, storage persisted independently of pod lifecycle.

## CKAD Tips

- `volumeClaimTemplates` auto-creates one PVC per pod named `<template>-<statefulset>-<ordinal>` (e.g. `www-web-0`); these PVCs are **not** deleted with the StatefulSet.
- The StatefulSet's `serviceName` must point at a headless Service (`clusterIP: None`) so each pod gets stable DNS.
- Inspect the generated storage with `kubectl get pvc` and `kubectl get pv`, and confirm every PVC is `Bound`.
- Prove persistence by writing data, running `kubectl delete pod <name>`, and re-reading after the same-named pod is recreated.
- Set `storageClassName` inside `volumeClaimTemplates` (not on a standalone PVC) to control provisioning.

## Key Takeaway

`volumeClaimTemplates` gives each StatefulSet pod its own dynamically provisioned PVC tied to its ordinal identity, so data survives pod deletion and rescheduling.
