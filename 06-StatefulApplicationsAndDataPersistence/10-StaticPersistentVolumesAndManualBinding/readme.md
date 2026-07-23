# Static PersistentVolumes and Manual Binding

When storage is **pre-provisioned** (NFS share, local disk, cloud disk created outside Kubernetes), you create a **PV** manually and a **PVC** that binds to it. CKAD occasionally tests this pattern.

For dynamic provisioning, see [09-StorageClassesAccessModesAndDynamicProvisioning](../09-StorageClassesAccessModesAndDynamicProvisioning/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `static-pv.yaml` | Pre-provisioned 2Gi PV with `storageClassName: manual` |
| `static-pvc.yaml` | PVC that binds to the PV by matching class, size, and access mode |
| `static-storage-deployment.yaml` | Deployment using the bound PVC |

## Binding Rules

A PVC binds to a PV when **all** of these match:

- `accessModes` are compatible
- `storageClassName` matches (or both unset for legacy binding)
- PVC requested storage ≤ PV capacity

## Step 1: Create PV Then PVC

```bash
kubectl apply -f static-pv.yaml
kubectl get pv static-pv-1
kubectl apply -f static-pvc.yaml
kubectl get pvc static-pvc
```

Both should show `Bound` and reference each other.

```bash
kubectl get pv static-pv-1 -o jsonpath='{.spec.claimRef.name}{"\n"}'
```

## Step 2: Deploy the App

```bash
kubectl apply -f static-storage-deployment.yaml
kubectl logs -l app=static-storage-app
```

## Static vs Dynamic

| | Dynamic | Static |
|--|---------|--------|
| Who creates PV | StorageClass provisioner | Admin (you) |
| PVC `storageClassName` | Cluster default or named class | Must match PV |
| Exam frequency | More common | Occasional |

## hostPath Note

This demo uses `hostPath` for local clusters (minikube/kind). **Not for production** — data is tied to one node. On the exam, the PV spec may use NFS, iSCSI, or a cloud volume instead; the binding logic is the same.

## CKAD Tips

- Create **PV first**, then PVC.
- `storageClassName: ""` on PVC disables dynamic provisioning — forces static binding.
- `persistentVolumeReclaimPolicy: Retain` keeps data after PVC deletion (common for static PVs).

## Cleanup

```bash
kubectl delete -f static-storage-deployment.yaml -f static-pvc.yaml -f static-pv.yaml
```

## Key Takeaway

Static binding = admin creates PV, user creates matching PVC, Kubernetes binds them. Match `accessModes`, `storageClassName`, and capacity.
