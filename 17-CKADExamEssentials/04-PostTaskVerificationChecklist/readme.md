# Post-Task Verification Checklist

Every CKAD task should end with a **30-second verification**. Unverified work is how easy points are lost.

## Universal Checklist

Run these after every `kubectl apply`:

```bash
# 1. Object exists and is healthy
kubectl get <resource> -n <namespace>

# 2. Details / events if not Running or Bound
kubectl describe <resource> -n <namespace>

# 3. Pods running?
kubectl get pods -n <namespace> -l <selector>

# 4. Recent events (sorted)
kubectl get events -n <namespace> --sort-by=.lastTimestamp | tail -10
```

## Per-Resource Quick Checks

| Task type | Verify with |
|-----------|-------------|
| Deployment | `kubectl rollout status deploy/<name>` |
| Service | `kubectl get endpoints <svc>` — must show Pod IPs |
| Ingress | `kubectl describe ingress <name>` — rules and backend |
| ConfigMap/Secret mount | `kubectl exec <pod> -- cat <mount-path>` |
| Env var injection | `kubectl exec <pod> -- printenv \| grep <KEY>` |
| PVC | `kubectl get pvc` — status **Bound** |
| Job | `kubectl get jobs` — **COMPLETE** |
| CronJob | `kubectl get cronjob` — schedule correct |
| NetworkPolicy | test from allowed/blocked Pod (if CNI supports) |
| RBAC | `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:...` |
| HPA | `kubectl get hpa` — targets and current metrics |
| Probes | `kubectl describe pod` — no probe failures in Events |

## Red Flags — Stop and Fix

| Symptom | Likely cause |
|---------|--------------|
| Pod `Pending` | requests too high, affinity/selector, missing toleration |
| Pod `CrashLoopBackOff` | wrong command, probe too aggressive, missing config |
| Pod `ImagePullBackOff` | wrong image name/tag, missing imagePullSecret |
| Service no endpoints | selector ≠ Pod labels |
| PVC `Pending` | no StorageClass, size/accessMode mismatch |
| Ingress 404 | wrong host/path, backend Service port wrong |
| Permission denied (API) | wrong SA, Role missing verb, RoleBinding namespace |

## One-Liner Sanity Commands

```bash
kubectl get all -n <namespace>
kubectl get pods -n <namespace> -o wide
kubectl logs <pod> -n <namespace> --tail=20
kubectl logs <pod> -n <namespace> -c <container>   # multi-container
```

## Exam Habit

Before clicking **Next** on a task:

1. Re-read the task requirement (one line).
2. Run **one** targeted verify command proving it is met.
3. Only then move on.

## Key Takeaway

`get` → `describe` → `logs`/`exec`/`endpoints` is the exam safety net. Thirty seconds of verification beats five minutes redoing a later task because the Service had no endpoints.
