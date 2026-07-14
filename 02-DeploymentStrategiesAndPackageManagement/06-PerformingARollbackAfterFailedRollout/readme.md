# Perform a Rollback After a Failed Rollout

## Scenario
Deploy a working version of `api-service` (nginx:1.25.1), then simulate a bad update
by changing the image to a non-existent tag. Observe the failure and roll back.

## Steps

### 1. Deploy the initial working version
```bash
kubectl apply -f fail-rollback-demo.yaml
```
This creates a Deployment with 3 replicas running `nginx:1.25.1`.

### 2. Check rollout history (revision 1 should exist)
```bash
kubectl rollout history deploy api-service
```

### 3. Simulate a bad update — change the image to a broken tag
```bash
kubectl edit deploy api-service
```
Change the image to something invalid, e.g. `nginx:does-not-exist`, then save.

### 4. Watch the rollout fail
```bash
kubectl get deploy api-service
kubectl rollout status deploy api-service
```
The rollout will hang because pods can't pull the bad image.

### 5. Confirm pods are stuck in ImagePullBackOff
```bash
kubectl get pods
kubectl describe pod <pod-name>
```
Look for `ImagePullBackOff` or `ErrImagePull` in the events section.

### 6. Roll back to the last working revision
```bash
kubectl rollout undo deploy api-service
```
Kubernetes rolls back to revision 1 (nginx:1.25.1).

### 7. Verify recovery
```bash
kubectl get pods
kubectl rollout history deploy api-service
```
All pods should return to `Running` and a new revision entry will appear in history.

## Roll back to a specific revision
```bash
kubectl rollout undo deploy api-service --to-revision=1
```

## Notes
- `kubectl rollout history` shows all revisions. Use `--revision=<n>` to inspect a specific one.
- A rollback itself creates a new revision (it does not delete history).
- `kubectl rollout status` blocks until the rollout completes or fails.
- The `CHANGE-CAUSE` column in history is populated from the `kubernetes.io/change-cause` annotation.

## Transcript Enhancements (Preserved Notes Kept)

### Failure Signal Pattern

For bad image tag scenarios, this sequence is typical:

1. rollout status hangs at partial progress
2. pods show `ImagePullBackOff` or `ErrImagePull`
3. describe events reveal image tag resolution failure

### Fast Recovery Pattern

```bash
kubectl rollout undo deploy api-service
kubectl rollout status deploy api-service
```

Use immediate undo first, then target explicit revision if needed.


