# Implementing an Indexed Parallel Job

This demo creates a Kubernetes Job with `completionMode: Indexed` to distribute work across multiple parallel pods, each with a unique index.

## Use Case

Process 50 data chunks using 10 worker pods, running 5 at a time. Each pod knows its index and calculates which chunks to process.

## YAML Example

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: unique-chunk-worker-job
spec:
  completions: 10
  parallelism: 5
  completionMode: Indexed
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: worker:1.0
          command: ["/bin/sh", "-c"]
          args:
            - |
              INDEX=$JOB_COMPLETION_INDEX
              CHUNKS_PER_WORKER=5
              START=$((INDEX * CHUNKS_PER_WORKER))
              END=$(((INDEX + 1) * CHUNKS_PER_WORKER))
              echo "I am Worker with unique Index $INDEX"
              echo "My assigned work is to process chunks $START through $END"
              process-chunks.sh $START $END
              echo "processing is complete for my specific range."
```

## Deploy and Monitor

```bash
kubectl apply -f indexed-worker-job.yaml

# Watch completions increase: 0/10 → 5/10 → 10/10
kubectl get job unique-chunk-worker-job --watch

kubectl logs -l job-name=unique-chunk-worker-job --all-containers=true --max-log-requests=20
```

## Verify Index Assignment

```bash
# List all pods with their assigned indices
kubectl get pods -l job-name=unique-chunk-worker-job --show-labels

# Look for label: batch.kubernetes.io/job-completion-index=<N>
```

You should see 10 pods with indices 0–9.

## Inspect Pod Logs

```bash
# Get a pod name (e.g., unique-chunk-worker-job-abc123)
POD=$(kubectl get pods -l job-name=unique-chunk-worker-job -o jsonpath='{.items[0].metadata.name}')

# View logs to confirm the pod's index and assigned work range
kubectl logs $POD
```

Example output:

```
I am Worker with unique Index 9
My assigned work is to process chunks 46 through 50
processing is complete for my specific range.
```

Different pods will show different indices and corresponding chunk ranges.

## Why Indexed Jobs Matter

- **No external queue needed**: The index is built into the Job
- **Deterministic work distribution**: Pod N always processes the same chunk range
- **Parallelism without collision**: Each pod knows exactly what to do
- **Ideal for static, partitioned workloads**: Video processing, data sharding, hyperparameter tuning

## CKAD Tips

- The three fields that make an indexed parallel Job: `completionMode: Indexed`, `completions` (number of indices), and `parallelism` (how many run at once).
- Reference `$JOB_COMPLETION_INDEX` inside the container's `command`/`args` to compute each pod's slice of the work.
- With `completionMode: Indexed` you MUST also set `completions`; omitting it is a common mistake.
- Confirm indices with `kubectl get pods -l job-name=<job> --show-labels` (look for `batch.kubernetes.io/job-completion-index`) and read a pod with `kubectl logs $POD`.
- `restartPolicy: Never` is used here so each attempt is a fresh pod tied to its index.

## Key Takeaway

An indexed parallel Job hands each pod a stable `JOB_COMPLETION_INDEX`, letting workers deterministically self-assign a slice of the workload (e.g. chunks) without any external queue, while `parallelism` bounds concurrency.
