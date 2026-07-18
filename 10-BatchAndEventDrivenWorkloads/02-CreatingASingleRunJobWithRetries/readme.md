# Creating a Single-Run Job with Retries

This demo creates a Kubernetes Job configured with `backoffLimit` to automatically retry if it fails, then inspects the history of failed and successful pods.

## Use Case

A nightly data cleanup script connects to a remote database. Occasionally the connection times out due to temporary network load. Without retries, the cleanup is missed. With `backoffLimit`, the Job automatically attempts multiple times before giving up.

## YAML Example

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-on-failure-job
spec:
  backoffLimit: 5          # up to 5 total attempts (original + 4 retries)
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: myimage:1.0
          command: ["/bin/sh", "-c"]
          args: ["script.sh"]
```

If your script is designed to fail 3 times before succeeding on the 4th attempt, `backoffLimit: 5` provides enough room for success within the limit.

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
