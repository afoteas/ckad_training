# PVC, EmptyDir, and Ephemeral Storage Examples

## Overview
This folder covers three storage patterns in Kubernetes:

| File | Type | Lifetime | Use case |
|---|---|---|---|
| `emptydir-pod.yaml` | `emptyDir` | Pod lifetime | Scratch space, caches |
| `csi-ephemeral-pod.yaml` | Inline ephemeral PVC | Pod lifetime | Dynamic provisioned scratch |
| `my-pvc.yaml` + `app-deployment.yaml` | PersistentVolumeClaim | Beyond pod lifetime | State that survives restarts |

---

## 1. EmptyDir — pod-scoped scratch storage

`emptyDir` is created when a pod is scheduled and deleted when the pod is removed.
Data is lost if the pod restarts or is deleted.

```bash
kubectl apply -f emptydir-pod.yaml
kubectl get pod emptydir-demo
kubectl exec -it emptydir-demo -- cat /cache/msg.txt
```
Expected output: `hello from emptyDir`

Cleanup:
```bash
kubectl delete -f emptydir-pod.yaml
```

---

## 2. Inline Ephemeral Volume (PVC-backed, pod lifetime)

Uses `volumes[].ephemeral.volumeClaimTemplate` — Kubernetes dynamically provisions a PVC
for the pod and deletes it when the pod is removed. This requires a default StorageClass.

```bash
kubectl apply -f csi-ephemeral-pod.yaml
kubectl wait --for=condition=Ready pod/csi-ephemeral-demo --timeout=90s
kubectl get pod csi-ephemeral-demo
kubectl logs csi-ephemeral-demo --tail=5
```

Verify the auto-created PVC (named after the pod):
```bash
kubectl get pvc | grep csi-ephemeral-demo
```

Cleanup (also deletes the auto-provisioned PVC):
```bash
kubectl delete -f csi-ephemeral-pod.yaml
```

### Why a plain inline CSI volume does not work here

An earlier version used:
```yaml
volumes:
  - name: csi-ephemeral-vol
    csi:
      driver: example.csi.k8s.io
```
That driver name is a placeholder — no CSI driver with that name is registered in a
standard Docker Desktop cluster. The pod would hang in `ContainerCreating` with a
`FailedMount` event.

To confirm which drivers are available:
```bash
kubectl get csidrivers
kubectl describe pod csi-ephemeral-demo   # shows FailedMount in Events
```

The fix is to use `ephemeral.volumeClaimTemplate` instead, which uses the default
StorageClass (present on Docker Desktop) rather than requiring a specific CSI driver.

---

## 3. PersistentVolumeClaim mounted to a Deployment

Data written to the PVC survives pod restarts and rescheduling (within the same node,
since `accessMode: ReadWriteOnce`). The Deployment checks whether data already exists
from a previous run to demonstrate persistence.

### Create the PVC
```bash
kubectl apply -f my-pvc.yaml
kubectl get pvc log-storage
```
The PVC status should show `Bound` once the default StorageClass provisions it.

### Deploy the app
```bash
kubectl apply -f app-deployment.yaml
kubectl get pod -l app=stateful-app
kubectl logs -l app=stateful-app
```
First run output: `--- Writing NEW Data ---`

### Prove persistence — delete and recreate the pod
```bash
kubectl rollout restart deployment/stateful-app-demo
kubectl logs -l app=stateful-app
```
Second run output: `--- Persistence Confirmed! ---`

### Inspect the PVC binding
```bash
kubectl describe pvc log-storage
kubectl get pv
```

### Cleanup
```bash
kubectl delete -f app-deployment.yaml
kubectl delete -f my-pvc.yaml
```
Deleting the PVC also releases and deletes the underlying PersistentVolume (default
`reclaimPolicy: Delete` on Docker Desktop's StorageClass).

---

## Key concepts

- **emptyDir** — simplest ephemeral storage, no provisioning needed, dies with the pod.
- **ephemeral volumeClaimTemplate** — PVC-backed but still pod-scoped; useful when you
  need a real block/file volume temporarily without managing its lifecycle manually.
- **PVC + Deployment** — decouples storage from the pod; the volume outlives individual
  pod instances, enabling stateful workloads.
- `accessModes: ReadWriteOnce` — volume can be mounted read-write by **one node** at a
  time. Use `ReadWriteMany` (requires a compatible StorageClass) for multi-replica access.
