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
