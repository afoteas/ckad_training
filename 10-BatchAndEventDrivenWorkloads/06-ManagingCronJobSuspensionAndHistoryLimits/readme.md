# Managing CronJob Suspension and History Limits

This demo shows how to configure a CronJob with explicit history limits to prune old jobs, and how to suspend the CronJob during maintenance windows.

## Use Case

A backup CronJob runs every hour. Over time, successful and failed jobs accumulate, cluttering the cluster and slowing etcd. Policy: keep only the 2 most recent successful backups and 1 failed backup. Additionally, suspend the CronJob during a 2-hour maintenance window.

## YAML Example with History Limits

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-pruner-cronjob
spec:
  schedule: "* * * * *"                    # Every minute (for testing)
  successfulJobsHistoryLimit: 2            # Keep only 2 successful Jobs
  failedJobsHistoryLimit: 1                # Keep only 1 failed Job
  concurrencyPolicy: Allow
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: backup
              image: backup-worker:1.0
              command: ["/bin/sh", "-c"]
              args:
                - |
                  RAND=$RANDOM
                  if [ $((RAND % 5)) -eq 0 ]; then
                    exit 1  # ~20% chance of failure for testing
                  else
                    echo "Backup succeeded"
                    exit 0
                  fi
```

## Deploy

```bash
kubectl apply -f history-pruner-cronjob.yaml
```

## Monitor CronJob Status

```bash
kubectl get cronjob backup-pruner-cronjob
```

Output shows:

- `SCHEDULE` — the cron expression
- `SUSPEND` — whether the CronJob is suspended (false = running)
- `ACTIVE` — number of currently running Jobs
- `LAST SCHEDULE` — when the last Job was created

## View Job History

```bash
# After waiting a few minutes for jobs to accumulate
kubectl get jobs

# Only 2–3 jobs should remain (the history limit enforces cleanup)
```

The CronJob controller automatically deletes old Jobs as they exceed the configured limits.

## Suspend the CronJob

Temporarily halt scheduling (e.g., during maintenance):

```bash
kubectl patch cronjob backup-pruner-cronjob \
  -p '{"spec":{"suspend":true}}'
```

Verify suspension:

```bash
kubectl get cronjob backup-pruner-cronjob
```

The `SUSPEND` column should show `true`. The `LAST SCHEDULE` field will stop updating.

## Resume the CronJob

```bash
kubectl patch cronjob backup-pruner-cronjob \
  -p '{"spec":{"suspend":false}}'
```

The CronJob will immediately resume scheduling on the next cron interval.

## Why History Limits Matter

- **etcd performance**: Thousands of old Job objects slow down the API server and bloat etcd
- **clarity**: Developers see only relevant recent Jobs, not years of history
- **cost**: Fewer objects = smaller database = lower cloud storage costs
- **balance**: Keep enough history for debugging (failed Jobs) while pruning old successes
