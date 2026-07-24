# StorageClasses, Access Modes, and Dynamic Provisioning

Most clusters provision storage **dynamically**: you create a PVC, the StorageClass provisions a PV automatically. CKAD may ask you to write a PVC with the correct `accessModes` and `storageClassName`.

For basic PVC mounting, see [09-CreatingAPVCAndMountingItInADeployment](../../01-WorkloadandContainerImageFundamentals/09-CreatingAPVCAndMountingItInADeployment/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `storageclass.yaml` | Example StorageClass (reference; adjust `provisioner` for your cluster) |
| `dynamic-pvc.yaml` | PVC requesting 1Gi with `ReadWriteOnce` |
| `dynamic-storage-deployment.yaml` | Deployment mounting the PVC at `/data` |

## Access Modes

| Mode | Abbrev | Meaning |
|------|--------|---------|
| ReadWriteOnce | RWO | One node can mount read/write |
| ReadOnlyMany | ROX | Many nodes read-only |
| ReadWriteMany | RWX | Many nodes read/write |

**CKAD default:** `ReadWriteOnce` for most block storage.

## Dynamic Provisioning Flow

```text
PVC (with storageClassName) → StorageClass → provisioner creates PV → PVC Bound
```

## Step 1: Check Your Cluster's StorageClasses

```bash
kubectl get storageclass
```

Note the default class (annotation `storage.k8s.io/is-default-class: "true"`).

## Step 2: Create PVC and Deploy

Edit `dynamic-pvc.yaml` if your default class is not named `standard`, then:

```bash
kubectl apply -f dynamic-pvc.yaml
kubectl get pvc dynamic-data
kubectl apply -f dynamic-storage-deployment.yaml
kubectl logs -l app=dynamic-storage-app
```

PVC should show `Bound`. Data persists across Pod restarts.

## StorageClass Fields (Know for Exam)

```yaml
provisioner: <driver>              # e.g. kubernetes.io/aws-ebs, rancher.io/local-path
volumeBindingMode: Immediate       # or WaitForFirstConsumer
reclaimPolicy: Delete              # or Retain
allowVolumeExpansion: true
```

## Troubleshooting PVC Stuck Pending

```bash
kubectl describe pvc dynamic-data
kubectl get storageclass
```

Common causes: no default StorageClass, wrong `storageClassName`, or provisioner unavailable.

## Cleanup

```bash
kubectl delete -f dynamic-storage-deployment.yaml -f dynamic-pvc.yaml
```

## CKAD Tips

- PVC is **namespaced**; PV is **cluster-scoped**.
- Omit `storageClassName` to use the default class; set `storageClassName: ""` to disable dynamic provisioning (static binding only).
- `volumeMode: Filesystem` (default) vs `Block` — rarely tested; default is fine.

## Key Takeaway

Create a PVC with the right `accessModes` and `storageClassName`; the cluster provisions a PV automatically. Always verify `kubectl get pvc` shows `Bound` before deploying the workload.
