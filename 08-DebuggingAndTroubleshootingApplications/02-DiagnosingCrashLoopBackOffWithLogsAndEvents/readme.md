# Diagnosing CrashLoopBackOff with Logs & Events

This lesson walks through two startup failures and shows how to isolate root cause with `kubectl get`, `describe`, `logs`, and events.

## Scenario 1: ImagePullBackOff Example

Deploy a pod with an invalid image tag:

```bash
kubectl apply -f 01-imagepull-failure.yaml
kubectl get pods
kubectl describe pod imagepull-demo
kubectl get events --sort-by='.lastTimestamp'
```

What to look for:

- `ErrImagePull` and `ImagePullBackOff`
- event messages like `Failed to pull image`
- registry message indicating manifest/tag not found

Cleanup:

```bash
kubectl delete pod imagepull-demo
```

## Scenario 2: CrashLoopBackOff Example

Deploy a pod that exits with a failure:

```bash
kubectl apply -f 02-crashloop-failure.yaml
kubectl get pods
kubectl logs crashloop-demo
kubectl describe pod crashloop-demo
```

What to look for:

- restart count increasing over time
- status cycling into `CrashLoopBackOff`
- events showing repeated backoff restarts
- application-level fatal error in logs

Cleanup:

```bash
kubectl delete pod crashloop-demo
```

## Key Debugging Sequence

1. Confirm pod status and restarts.
2. Inspect pod events with `describe`.
3. Read logs for application error details.
4. Use cluster events for timeline context.

## CKAD Tips

- Distinguish the two failure classes fast: `ImagePullBackOff`/`ErrImagePull` is a pull problem (fix the image/tag/credentials), while `CrashLoopBackOff` is the app exiting after start (fix via logs).
- For crash loops, `kubectl logs <pod>` may be empty for the current attempt — use `kubectl logs <pod> --previous` to read the last crashed container's output.
- Watch the `RESTARTS` column with `kubectl get pods -w` to confirm a genuine restart loop rather than a one-off failure.
- `kubectl describe pod <pod>` surfaces the pull/backoff reason text and event history in one place; combine with `kubectl get events --sort-by='.lastTimestamp'` for ordering.
- Always clean up demo pods with `kubectl delete pod <name>` so leftover failing pods don't skew later checks.

## Key Takeaway

A reliable debug sequence — status/restarts, then `describe`, then `logs` (with `--previous`), then sorted events — separates image-pull failures from application crashes and pinpoints root cause quickly.