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

## Example YAML Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: example-job
spec:
  completions: 3
  parallelism: 2
  backoffLimit: 4
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
```

- Runs 3 successful Pods
- Two Pods at a time (`parallelism=2`)
- Retries failed Pods up to 4 times

## Full Job Spec Reference

| Field | Type | Default | Description |
|---|---|---|---|
| `completions` | integer | 1 | Number of pods that must complete successfully |
| `parallelism` | integer | 1 | Max pods running simultaneously |
| `backoffLimit` | integer | 6 | Max retries before Job is marked Failed |
| `activeDeadlineSeconds` | integer | none | Max wall-clock time for the entire Job |
| `ttlSecondsAfterFinished` | integer | none | Auto-delete Job N seconds after completion |
| `suspend` | boolean | false | Pause the Job (no new pods scheduled) |
| `completionMode` | string | `NonIndexed` | `NonIndexed` (any pod counts) or `Indexed` (each pod gets a unique index) |
| `manualSelector` | boolean | false | Allow custom pod selector instead of auto-generated |
| `selector` | object | auto | Label selector for pods (used with `manualSelector: true`) |
| `podFailurePolicy` | object | none | Rules for handling specific pod failure conditions (exit codes, conditions) |
| `template.spec.restartPolicy` | string | — | Must be `Never` or `OnFailure` for Jobs |

## Best Practices

- always set `restartPolicy: Never` in the pod template
- use `kubectl describe job <name>` to monitor progress and retry count
- set `backoffLimit` conservatively: 1–2 for non-critical tasks, 5–6 for critical ones
- avoid high `parallelism` if the task contends for limited backend resources (DB connection pool, rate-limited API)
- use `activeDeadlineSeconds` to prevent runaway jobs
- for scheduled tasks, use CronJob instead of manual Job creation

## CKAD Tips

- Generate a Job fast with `kubectl create job pi --image=perl -- perl -Mbignum=bpi -wle "print bpi(2000)"`, then `--dry-run=client -o yaml` to a file and edit.
- Remember the pod template `restartPolicy` MUST be `Never` or `OnFailure`; the default `Always` is rejected for Jobs.
- Know the default values cold: `completions: 1`, `parallelism: 1`, `backoffLimit: 6`.
- `backoffLimit` counts pod *failures* (retries), while `activeDeadlineSeconds` is a hard wall-clock cap that fails the Job regardless of retries left.
- Watch progress and retry counts with `kubectl get job <name> -w` and `kubectl describe job <name>`.

## Key Takeaway

A Job runs pods to successful completion and retries failures up to `backoffLimit`, unlike a Deployment which keeps pods running forever — always set an appropriate `restartPolicy` (`Never`/`OnFailure`) and tune `completions`, `parallelism`, and `backoffLimit` to match the task.
