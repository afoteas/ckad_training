# Volumes in Pods

This lesson covers how Kubernetes volumes provide data access inside Pods, including temporary and configuration-oriented storage types.

## Why Volumes Matter

Container images are typically stateless. Any data that must survive process restarts or be shared between containers needs an external volume mount.

Within a Pod, volumes enable:

- shared file access across containers
- temporary scratch/caching storage
- mounted configuration and secrets

## Volume Types Covered

### emptyDir

- created when Pod is scheduled
- deleted when Pod is removed
- ideal for temporary files and sidecar file handoff

### CSI Ephemeral

- temporary storage tied to Pod lifecycle
- useful when a CSI driver provides short-lived storage features

## Quick Comparison

| Pattern | Lifetime | Provisioning | Typical use |
|---|---|---|---|
| `emptyDir` | Pod lifetime | none | cache/scratch/shared temp files |
| inline ephemeral (`ephemeral.volumeClaimTemplate`) | Pod lifetime | dynamic PVC | temporary storage with StorageClass support |
| PVC (lesson 09) | beyond Pod | static or dynamic PV | durable application state |

### ConfigMap and Secret Volume (conceptual)

- ConfigMap for non-sensitive settings
- Secret for credentials and keys
- injected at runtime instead of baking into images

## Files in This Lesson

- `emptydir-pod.yaml`
- `csi-ephemeral-pod.yaml`

## Run the Examples

### 1) emptyDir demo

```bash
kubectl apply -f emptydir-pod.yaml
kubectl get pod emptydir-demo
kubectl exec -it emptydir-demo -- cat /cache/msg.txt
```

Cleanup:

```bash
kubectl delete -f emptydir-pod.yaml
```

### 2) CSI ephemeral demo

```bash
kubectl apply -f csi-ephemeral-pod.yaml
kubectl get pod csi-ephemeral-demo
kubectl logs csi-ephemeral-demo --tail=20
```

If your cluster supports dynamic provisioning for the configured StorageClass, you can also verify auto-created claims:

```bash
kubectl get pvc | grep csi-ephemeral-demo || true
```

If your local cluster lacks a compatible CSI driver, this demo may fail mount. Check events:

```bash
kubectl describe pod csi-ephemeral-demo
kubectl get csidrivers
```

## Common Ephemeral Volume Pitfall

A frequent issue is using a placeholder CSI driver name in Pod spec, for example:

```yaml
volumes:
	- name: csi-ephemeral-vol
		csi:
			driver: example.csi.k8s.io
```

If no driver with that name is installed in the cluster, the Pod remains in `ContainerCreating` with `FailedMount` events.

Practical fix:

1. use a real installed CSI driver name, or
2. use `ephemeral.volumeClaimTemplate` with a working default StorageClass.

This keeps volume lifecycle Pod-scoped while avoiding unsupported driver references.

## Previous Notes (Preserved)

The detailed storage notes previously discussed in workload context are intentionally preserved here where they belong.

### emptyDir recap

- created when Pod starts on a node
- shared by all containers in that Pod
- permanently removed when Pod is deleted

### Ephemeral recap

- useful for short-lived test/runtime data
- designed to avoid manual storage lifecycle management for temporary workloads

### ConfigMap and Secret recap

- ConfigMap: non-sensitive configuration injection
- Secret: credential/token/key injection
- both can be mounted as files or exposed as environment variables

## Choosing Between Temporary Volume Options

1. Need simple Pod-local temporary storage: emptyDir.
2. Need Pod-scoped storage with CSI-specific capabilities: CSI ephemeral.
3. Need data to outlive Pod lifecycle: use PVC (lesson 09).

## Summary

Volume choice is driven by lifecycle needs. For Pod-lifetime data, use emptyDir or ephemeral patterns. For durable application state, move to PVC-backed storage.
