# Managing CronJob Suspension and History Limits

This demo shows how to configure a CronJob with explicit history limits to prune old jobs, and how to suspend the CronJob during maintenance windows.

## Use Case

A backup CronJob runs every hour. Over time, successful and failed jobs accumulate, cluttering the cluster and slowing etcd. Policy: keep only the 2 most recent successful backups and 1 failed backup. Additionally, suspend the CronJob during a 2-hour maintenance window.

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

## Read CronJob Logs

You cannot read logs directly from the CronJob object. A CronJob creates Jobs, and those Jobs create Pods. Read logs from the latest generated Job or its Pods.

```bash
# Find the most recently created Job for this CronJob
JOB=$(kubectl get jobs --sort-by=.metadata.creationTimestamp -o name \
  | grep 'job.batch/backup-pruner-cronjob-' \
  | tail -n 1 \
  | cut -d/ -f2)

# Stream logs from that Job
kubectl logs -f job/"$JOB"

# Or stream logs from all Pods belonging to that Job
kubectl logs -f -l job-name="$JOB" --all-containers=true --max-log-requests=20
```

To list all Jobs created by this CronJob:

```bash
kubectl get jobs | grep '^backup-pruner-cronjob-'
```

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
