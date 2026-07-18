# CronJob Features and Concurrency Policy

A CronJob is a wrapper around the Job resource that automates recurring task execution at specific times using standard cron syntax.

## Why CronJobs

Essential for operational tasks like:

- daily database backups
- scheduled log rotation
- periodic data cleanup
- recurring health checks
- nightly reports

Without CronJobs, you would manually trigger Jobs or rely on external schedulers outside Kubernetes.

## Cron Syntax: Five Fields

```
minute  hour  day-of-month  month  day-of-week
  0-59   0-23      1-31      1-12      0-6
```

Common patterns:

| Expression | Meaning |
|---|---|
| `0 0 * * *` | Every day at midnight |
| `0 */4 * * *` | Every 4 hours |
| `0 9-17 * * 1-5` | 9am to 5pm, Monday–Friday |
| `*/10 * * * *` | Every 10 minutes |
| `0 0 1 * *` | First day of every month at midnight |

## Core CronJob Fields

| Field | Purpose |
|---|---|
| `schedule` | Cron expression defining when to run |
| `concurrencyPolicy` | How to handle overlapping executions |
| `startingDeadlineSeconds` | Max seconds past scheduled time to start (if missed) |
| `successfulJobsHistoryLimit` | Keep this many successful Job objects (default: 3) |
| `failedJobsHistoryLimit` | Keep this many failed Job objects (default: 1) |
| `suspend` | If `true`, pause scheduling until set to `false` |

## Concurrency Policy

Controls what happens if a new execution is scheduled before the previous one finishes:

| Policy | Behavior |
|---|---|
| `Allow` (default) | Let both run simultaneously |
| `Forbid` | Skip the new execution if one is running |
| `Replace` | Cancel the running Job and start a new one |

Use `Forbid` to prevent resource contention (e.g., backup jobs). Use `Replace` for jobs that must run at exact times even if previous run is incomplete.

## Example: Daily Backup with Forbid Policy

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 0 * * *"           # Every day at midnight
  concurrencyPolicy: Forbid       # Skip if backup is still running
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: mybackup:1.0
              command: ["/bin/bash", "-c"]
              args: ["backup.sh"]
```

## Best Practices

- use `Forbid` for jobs that are resource-intensive or long-running
- set `successfulJobsHistoryLimit` conservatively to avoid etcd bloat
- set `failedJobsHistoryLimit` higher than successful to aid debugging
- use `startingDeadlineSeconds` to avoid cascading retries if the controller is down
- always test the cron schedule expression before deploying to production
