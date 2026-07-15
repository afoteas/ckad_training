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
