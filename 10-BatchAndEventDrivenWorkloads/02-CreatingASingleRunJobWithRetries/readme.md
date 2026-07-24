# Creating a Single-Run Job with Retries

This demo creates a Kubernetes Job configured with `backoffLimit` to automatically retry if it fails, then inspects the history of failed and successful pods.

## Use Case

A nightly data cleanup script connects to a remote database. Occasionally the connection times out due to temporary network load. Without retries, the cleanup is missed. With `backoffLimit`, the Job automatically attempts multiple times before giving up.

## YAML Example

See [retrying-job.yaml](retrying-job.yaml) for the full example. 

Key points:
- `backoffLimit: 5` allows up to 5 total attempts (original + 4 retries)
- `restartPolicy: OnFailure` tells the kubelet to restart the pod container on failure, incrementing the retry counter
- The example uses an `emptyDir` volume to track failed attempts across restarts
- Once it succeeds on the 4th attempt, the Job completes

## Deploy and Monitor

```bash
kubectl apply -f retrying-job.yaml

# Watch status update from Pending → Running → Failed (retrying) → Complete
kubectl get job retry-on-failure-job --watch

# Check current Job status
kubectl get job retry-on-failure-job
```

Once the Job reaches `1/1` completions, it is complete.

## Inspect Pods and Logs

```bash
# List all pods created by this Job (shows failed and successful attempts)
kubectl get pods -l job-name=retry-on-failure-job

# View logs from a specific pod to see the failure and eventual success
kubectl logs <pod-name>
```

The logs show each failure attempt followed by the final successful attempt.

## Cleanup

```bash
kubectl delete job retry-on-failure-job
```

This deletes the Job and all associated pods.

## CKAD Tips

- `backoffLimit: N` means N+1 total attempts (1 original + N retries); if all fail the Job is marked `Failed`.
- With `restartPolicy: OnFailure` the kubelet restarts the container in place; with `Never` the controller spawns a brand-new pod per attempt — expect more pod objects to inspect.
- Failed and succeeded attempts are all findable via the label `job-name=<job>`: `kubectl get pods -l job-name=retry-on-failure-job`.
- Use `kubectl get job <name> --watch` to see `COMPLETIONS` go from `0/1` to `1/1`, and `kubectl describe job` to read the events/retry history.
- Grab logs from a specific attempt with `kubectl logs <pod-name>` before cleanup deletes them.

## Key Takeaway

`backoffLimit` lets a Job tolerate transient failures by automatically retrying until it succeeds or the limit is exhausted, so intermittent problems (like a flaky DB connection) don't cause a missed run.
