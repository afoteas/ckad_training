# Parallel and Indexed Jobs

For workloads that naturally divide into independent pieces, running them in parallel drastically improves speed and cluster utilization.

## Traditional Parallel Jobs (Fixed Completion)

All pods run the **same logic** until a fixed completion count is met.

In this mode, set `completions` to the total successful pods required and `parallelism` to the max pods running at once.

The Job controller ensures:

- 4 pods eventually exit with code 0
- Never more than 2 pods run simultaneously
- All pods receive the same container command

**Limitation**: Every pod is identical. The application itself must figure out which chunk to work on (usually via an external queue or locking mechanism). The Job controller provides no built-in unique identifier.

## Indexed Jobs (CompletionMode: Indexed)

Each pod is automatically assigned a **unique integer index** (`JOB_COMPLETION_INDEX` environment variable).

Enable indexed behavior with `completionMode: Indexed` and set `completions` to the number of unique indices required.

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

## Manifests in This Lesson

- `fixed-parallel-job.yaml`: fixed-completion parallel Job (4 completions, parallelism 2)
- `indexed-chunk-processor-job.yaml`: indexed Job that splits 50 chunks across 10 workers

## Full Example 1: Fixed Parallel Job

Apply and watch progress:

```bash
kubectl apply -f fixed-parallel-job.yaml
kubectl get job fixed-parallel-demo --watch
```

Verify pods and logs:

```bash
kubectl get pods -l job-name=fixed-parallel-demo
POD=$(kubectl get pods -l job-name=fixed-parallel-demo -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD"

# Follow logs live from all pods in this Job
kubectl logs -f -l job-name=fixed-parallel-demo --all-containers=true --max-log-requests=20
```

## Full Example 2: Indexed Chunk Processor

Apply and watch indexed completions:

```bash
kubectl apply -f indexed-chunk-processor-job.yaml
kubectl get job indexed-chunk-processor --watch
```

Verify index assignment:

```bash
kubectl get pods -l job-name=indexed-chunk-processor --show-labels
```

Look for label `batch.kubernetes.io/job-completion-index=<N>`.

Inspect a worker log:

```bash
POD=$(kubectl get pods -l job-name=indexed-chunk-processor -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD"

# Follow logs live from all indexed worker pods
kubectl logs -f -l job-name=indexed-chunk-processor --all-containers=true --max-log-requests=20
```

Expected output pattern:

- Worker 0 processes chunks 0-4
- Worker 1 processes chunks 5-9
- ...
- Worker 9 processes chunks 45-49

## Cleanup

```bash
kubectl delete -f fixed-parallel-job.yaml
kubectl delete -f indexed-chunk-processor-job.yaml
```

## Key Difference

| Aspect | Fixed Completion | Indexed |
|---|---|---|
| Pod uniqueness | All identical | Each has unique `JOB_COMPLETION_INDEX` |
| Success tracking | Total count | Per-index tracking |
| Use case | Generic parallelism | Partitioned workloads |

## CKAD Tips

- `parallelism` caps how many pods run at once; `completions` is how many must succeed — set both for fixed-completion parallel Jobs.
- Indexed Jobs require `completionMode: Indexed` AND a `completions` value; each pod gets its index via the `JOB_COMPLETION_INDEX` env var and the label `batch.kubernetes.io/job-completion-index`.
- Indexed Jobs retry only the failed index, not the whole batch — no external queue needed for partitioned work.
- Tail every pod at once with `kubectl logs -f -l job-name=<job> --all-containers=true --max-log-requests=20`.
- Find a pod's index quickly with `kubectl get pods -l job-name=<job> --show-labels`.

## Key Takeaway

Fixed-completion parallel Jobs run identical pods until a total success count is met, while Indexed Jobs give each pod a unique `JOB_COMPLETION_INDEX` for deterministic, per-index work distribution without an external coordinator.
