# Resizing Persistent Volumes and File Systems

Storage requirements grow over time. Kubernetes supports PVC expansion when prerequisites are met.

## Key Terms

- StorageClass: storage blueprint
- PVC: storage request
- PV: provisioned disk bound to the claim

## Preconditions for Expansion

1. StorageClass has `allowVolumeExpansion: true`
2. CSI/provisioner supports volume resize
3. Filesystem supports online growth (commonly `ext4` or `xfs`)

## Expansion Workflow

1. Edit PVC requested size upward (for example `1Gi` to `2Gi`)
2. Backend volume expands
3. Filesystem expands in pod (if supported)
4. App keeps running during process in most cases

## Example PVC Expansion YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
	name: data-pvc
spec:
	resources:
		requests:
			storage: 20Gi # increased from 10Gi
```

This represents the updated PVC request size after expansion.

## Important Limitations

- expansion is one-way (no native shrink)
- some apps may require restart to detect new free space
- monitor events and capacity fields during resize

## Useful Commands

```bash
kubectl get storageclass
kubectl get pvc
kubectl describe pvc <pvc-name>
kubectl get pv
kubectl exec <pod-name> -- df -h <mount-path>
```

## CKAD Tips

- Expansion only works when the StorageClass sets `allowVolumeExpansion: true` — verify with `kubectl get storageclass`.
- Grow a claim by editing it (`kubectl edit pvc <name>`) and raising `spec.resources.requests.storage`; you can only increase, never shrink.
- Track progress with `kubectl describe pvc <name>` (watch events and `status.conditions`) and confirm the new size with `kubectl exec <pod> -- df -h`.
- Some volumes stay in `FileSystemResizePending` until the pod is restarted to finish filesystem growth.

## Key Takeaway

Persistent volumes can grow (never shrink) when the StorageClass allows expansion and the driver/filesystem support it; edit the PVC's requested size, then verify the new capacity inside the pod.
