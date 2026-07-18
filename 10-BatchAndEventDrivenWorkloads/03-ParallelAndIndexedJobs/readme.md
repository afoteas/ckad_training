# Parallel and Indexed Jobs

For workloads that naturally divide into independent pieces, running them in parallel drastically improves speed and cluster utilization.

## Traditional Parallel Jobs (Fixed Completion)

All pods run the **same logic** until a fixed completion count is met.

```yaml
completions: 4      # must run 4 successful pods
parallelism: 2      # at most 2 running at the same time
```

The Job controller ensures:

- 4 pods eventually exit with code 0
- Never more than 2 pods run simultaneously
- All pods receive the same container command

**Limitation**: Every pod is identical. The application itself must figure out which chunk to work on (usually via an external queue or locking mechanism). The Job controller provides no built-in unique identifier.

## Indexed Jobs (CompletionMode: Indexed)

Each pod is automatically assigned a **unique integer index** (`JOB_COMPLETION_INDEX` environment variable).

```yaml
completions: 5
parallelism: 5
completionMode: Indexed    # activates unique index assignment
```

The Job controller:

- launches 5 pods
- assigns index 0, 1, 2, 3, 4 to each respectively
- injects `JOB_COMPLETION_INDEX` environment variable
- tracks success per index (e.g., if index 3 fails, only index 3 is retried)

## Use Cases for Indexed Jobs

- **data partitioning**: 100 files split into 100 pods; pod N processes file N
- **hyperparameter tuning**: each pod trains a model with unique hyperparameters
- **database sharding**: each pod processes a specific shard
- **map-reduce**: map phase distributes data chunks to pods
- **video/image processing**: each pod processes a unique video or image

## Example: Processing 50 Data Chunks with 10 Workers

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: chunk-processor
spec:
  completions: 10
  parallelism: 5
  completionMode: Indexed
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: worker
          image: processor:1.0
          env:
            - name: TOTAL_CHUNKS
              value: "50"
          command: ["/bin/sh", "-c"]
          args:
            - |
              INDEX=$JOB_COMPLETION_INDEX
              CHUNKS_PER_WORKER=$((TOTAL_CHUNKS / 10))
              START=$((INDEX * CHUNKS_PER_WORKER))
              END=$(((INDEX + 1) * CHUNKS_PER_WORKER))
              echo "Processing chunks $START to $END"
              process-chunks.sh $START $END
```

- Pod 0: processes chunks 0–4
- Pod 1: processes chunks 5–9
- ...
- Pod 9: processes chunks 45–49

## Key Difference

| Aspect | Fixed Completion | Indexed |
|---|---|---|
| Pod uniqueness | All identical | Each has unique `JOB_COMPLETION_INDEX` |
| Success tracking | Total count | Per-index tracking |
| Use case | Generic parallelism | Partitioned workloads |
