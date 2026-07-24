# Expanding a PVC for a Stateful Workload

This lesson walks through a hands-on PVC resize and filesystem verification.

## Example Scenario

- create `test-pvc` with `1Gi`
- run `test-pod` mounting PVC at `/data`
- write test file
- edit PVC to `2Gi`
- verify capacity and file data remain intact

## Deploy Initial Resources

```bash
kubectl apply -f pod-with-pvc.yaml
kubectl get pods -w
kubectl get pvc test-pvc
kubectl exec test-pod -- df -h /data
```

## Write and Verify Data

```bash
kubectl exec test-pod -- sh -c 'echo "hello-pvc" > /data/test.txt'
kubectl exec test-pod -- cat /data/test.txt
```

## Expand PVC

```bash
kubectl edit pvc test-pvc
```

Change:

```yaml
resources:
  requests:
    storage: 2Gi
```

## Monitor Resize

```bash
kubectl get pvc test-pvc -w
kubectl describe pvc test-pvc
kubectl exec test-pod -- df -h /data
kubectl exec test-pod -- cat /data/test.txt
```

Expected result:

- capacity increases to target size
- filesystem grows
- existing data remains readable

## CKAD Tips

- Resize a PVC in place with `kubectl edit pvc <name>` (or `kubectl patch`), increasing `spec.resources.requests.storage`.
- Confirm the backing StorageClass has `allowVolumeExpansion: true` before attempting the resize.
- Validate end-to-end: `kubectl get pvc -w`, `kubectl describe pvc <name>`, and `kubectl exec <pod> -- df -h <mount>`.
- Data written before the resize must remain intact — expansion never destroys existing files.

## Key Takeaway

Expanding a stateful workload's storage is a live edit to the PVC's requested size; the volume and filesystem grow online while existing data stays intact.
