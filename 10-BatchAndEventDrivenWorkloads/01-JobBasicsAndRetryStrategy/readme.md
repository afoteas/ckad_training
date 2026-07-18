# Job Basics and Retry Strategy

A Kubernetes Job is fundamentally different from a Deployment. Jobs are for workloads that run once and then finish, such as backups, data processing, batch emails, or database migrations.

## Key Differences: Job vs Deployment

| Aspect | Job | Deployment |
|---|---|---|
| **Purpose** | Run a task to completion | Keep pods running forever |
| **Success** | Pod exits with code 0 | Pods continuously serve traffic |
| **Failure handling** | Retry up to backoffLimit | Keep restarting automatically |
| **Suitable for** | One-off or batch tasks | Long-running services |

A Deployment will constantly restart pods after they exit, defeating the purpose of a batch task.

## Core Job Parameters

| Parameter | Purpose |
|---|---|
| `completions` | Total number of pods that must successfully finish before Job is complete |
| `parallelism` | Maximum number of pods allowed to run at the same time |
| `backoffLimit` | Maximum number of failed pod retries before Job is marked failed |
| `activeDeadlineSeconds` | Absolute maximum time (seconds) for the entire Job, regardless of progress |

## Pod Template Requirements

Inside the `template` section:

```yaml
template:
  spec:
    restartPolicy: Never  # CRITICAL: must be Never for Jobs
    containers:
      - name: worker
        image: myimage:1.0
        command: ["/bin/sh", "-c"]
        args: ["my-task.sh"]
```

Set `restartPolicy: Never` to prevent the kubelet from restarting the pod after it completes.

## Retry Mechanism

When a pod fails (exits with non-zero code):

1. Job controller does NOT repair the existing pod
2. It creates a **new** pod with the same spec
3. This continues until one succeeds OR `backoffLimit` is reached
4. Between attempts, exponential backoff delay increases
5. Once `backoffLimit` is exceeded, Job is marked **Failed**

## Best Practices

- always set `restartPolicy: Never` in the pod template
- use `kubectl describe job <name>` to monitor progress and retry count
- set `backoffLimit` conservatively: 1–2 for non-critical tasks, 5–6 for critical ones
- avoid high `parallelism` if the task contends for limited backend resources (DB connection pool, rate-limited API)
- use `activeDeadlineSeconds` to prevent runaway jobs
- for scheduled tasks, use CronJob instead of manual Job creation
