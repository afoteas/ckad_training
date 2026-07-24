# Jobs and CronJobs for Batch Processing

Jobs and CronJobs are for finite tasks, unlike Deployments that run continuously.

## Job vs CronJob

- Job: runs to completion once (manual/event triggered)
- CronJob: creates Jobs on a schedule

## Common Use Cases

- data migration
- report generation
- CSV import/export
- backups and cleanup tasks

## Job Characteristics

1. Runs until completion target is reached
2. Supports sequential or parallel execution
3. Retries failed pods (`backoffLimit`)
4. Tracks completion state

## CronJob Basics

A CronJob uses cron schedule syntax:

```yaml
apiVersion: batch/v1
kind: CronJob
spec:
  schedule: "0 0 * * *"
```

Then defines `jobTemplate` with container/image/command.

## Apply and Verify

```bash
kubectl apply -f backup-cronjob.yaml
kubectl get cronjobs
kubectl get jobs -w
```

## Best Practices

- make workloads idempotent
- set resource requests/limits
- use retry and deadline controls
- set history limits to prune old jobs
- avoid overlap with `concurrencyPolicy`
- monitor failures via logs and alerts

## CKAD Tips

- Generate quickly: `kubectl create job <name> --image=<img> -- <cmd>` and `kubectl create cronjob <name> --image=<img> --schedule="*/1 * * * *" -- <cmd>`.
- Append `--dry-run=client -o yaml` to scaffold a manifest you can edit before applying.
- Know the Job fields: `completions`, `parallelism`, `backoffLimit`, and `activeDeadlineSeconds`.
- For CronJobs remember `schedule`, `concurrencyPolicy` (`Allow`/`Forbid`/`Replace`), `startingDeadlineSeconds`, and the history limits.
- Trigger a Job immediately from a CronJob with `kubectl create job --from=cronjob/<name> <job-name>`; check output via `kubectl logs job/<name>`.

## Key Takeaway

Jobs run pods to completion with retry and parallelism controls, while CronJobs schedule Jobs on a cron expression; for the exam, master the imperative generators and the completion/retry fields.
