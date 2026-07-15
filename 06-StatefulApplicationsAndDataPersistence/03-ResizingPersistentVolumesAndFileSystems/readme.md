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
