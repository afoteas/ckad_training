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
