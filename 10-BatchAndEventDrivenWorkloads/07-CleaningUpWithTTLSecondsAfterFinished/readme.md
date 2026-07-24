# Cleaning Up with TTLSecondsAfterFinished

The TTL (Time To Live) controller automatically deletes finished Job objects after a specified duration, freeing cluster resources and keeping etcd lean.

## The Problem

After running hundreds of daily or hourly Jobs, completed Job objects accumulate in the API server and etcd. This:

- clutters output from `kubectl get jobs`
- slows the API server's ability to list resources
- bloats the etcd database, consuming storage
- requires manual cleanup scripts or administrative burden

## The Solution: TTLSecondsAfterFinished

Add this field to the Job spec to enable automatic cleanup:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: cleanup-demo
spec:
  ttlSecondsAfterFinished: 300    # delete 5 minutes after completion
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: worker:1.0
          command: ["/bin/sh", "-c"]
          args: ["echo 'Job finished'"]
```

When the Job finishes (either successfully or after hitting `backoffLimit`):

1. The TTL controller detects the status change to "Complete" or "Failed"
2. It starts a timer for 300 seconds (5 minutes)
3. When the timer expires, it **cascades delete** the Job and all associated Pods
4. Direct Kubernetes logs are deleted along with the Pods

## Lifecycle Example

```
Time 0:00  → Job completes successfully
Time 5:00  → TTL timer expires; Job and Pods deleted
           → kubectl logs <pod> will fail (logs are gone)
```

## Choosing TTL Values

| TTL | Use Case |
|---|---|
| 60–300 seconds | Short-lived, low-value jobs; fast cleanup |
| 1–3 hours | Batch jobs; time for operators to inspect logs if needed |
| Not set | Critical jobs; keep forever for audit/compliance |

**Balance**:

- Too short (e.g., 60s): operators miss logs for debugging failed jobs
- Too long (e.g., 30 days): etcd bloat and cluttered output
- Not set: unlimited growth; manual cleanup required

## Export Logs Before Deletion

TTL deletes Kubernetes-native logs, so export to a centralized platform first:

```bash
# Before TTL deletes the pod, capture logs
kubectl logs <job-pod-name> > /path/to/archive/job-123.log

# Or use a sidecar container to ship logs to a centralized logging system
# (Fluentd, Splunk, ELK, etc.)
```

## Operational Considerations

- **TTL is GA in Kubernetes 1.21+**: older versions may require manual cleanup
- **Cascading deletion**: deletes Job → deletes Pods → deletes logs
- **Audit requirements**: if you must retain all Job metadata for months/years, do NOT use TTL; instead, export to an external database
- **Active Jobs**: TTL only applies to finished Jobs; running Jobs are never affected

## Example: Batch Processing with TTL

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: daily-etl
spec:
  ttlSecondsAfterFinished: 86400    # keep for 24 hours after completion
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: etl
          image: etl:1.0
          command: ["etl-process.sh"]
```

After ETL completes, keep the Job for 1 day (86400 seconds) for debugging, then auto-delete.

## CKAD Tips

- `ttlSecondsAfterFinished` lives on the Job `spec` and starts counting only once the Job is `Complete` or `Failed` — running Jobs are untouched.
- `ttlSecondsAfterFinished: 0` deletes the Job immediately on finish; leaving it unset means the Job persists until you delete it.
- Deletion cascades: Job → Pods → their logs, so `kubectl logs` fails afterward — capture logs first (`kubectl logs <pod> > file.log`) or ship them to central logging.
- It applies to both standalone Jobs and the Jobs a CronJob creates, complementing `successfulJobsHistoryLimit`/`failedJobsHistoryLimit`.
- Feature is GA since Kubernetes 1.21, so assume it's available in exam clusters.

## Key Takeaway

`ttlSecondsAfterFinished` lets the TTL controller auto-delete finished Jobs (and their Pods/logs) after a set time, keeping the cluster and etcd clean — just export any logs you need before they're garbage-collected.
