# Creating a PVC and Mounting It in a Deployment

This lesson demonstrates the standard Kubernetes persistence flow:

1. PersistentVolume (PV): backing storage resource
2. PersistentVolumeClaim (PVC): application storage request
3. Deployment: mounts claim and consumes storage

## Why This Pattern

Pods are replaceable. Without persistent storage, application data is lost during pod recreation.

A PVC decouples data lifecycle from Pod lifecycle.

## Files in This Lesson

- `my-pvc.yaml`
- `app-deployment.yaml`

## Step-by-Step Demo

### 1) Create the PVC

```bash
kubectl apply -f my-pvc.yaml
kubectl get pvc
```

Wait for claim status to become `Bound`.

### 2) Deploy the app that mounts the claim

```bash
kubectl apply -f app-deployment.yaml
kubectl get pods
```

### 3) Validate application writes to mounted path

```bash
kubectl logs <pod-name>
```

### 4) Delete Pod to force recreation

```bash
kubectl delete pod <pod-name>
kubectl get pods
```

### 5) Verify data persistence

```bash
kubectl logs <new-pod-name>
```

Expected behavior: application finds data from previous run, proving persistence across Pod replacement.

## Key Concepts

- PVC is namespaced and requested by app teams.
- PV is cluster storage and can be provisioned dynamically via StorageClass.
- Deployment references PVC by claim name in `volumes` and `volumeMounts`.
- Pod can change; persistent storage binding remains.

## Troubleshooting

### PVC stuck Pending

- check default StorageClass exists
- check cluster storage provider status

Commands:

```bash
kubectl get storageclass
kubectl describe pvc <claim-name>
```

## Cleanup

```bash
kubectl delete -f app-deployment.yaml
kubectl delete -f my-pvc.yaml
```

## Summary

PVC-backed Deployments are the core stateful storage pattern in Kubernetes. They provide reliable data continuity even when Pods are recreated.
