# JobSet for Coordinated Multi-Job Workloads

A **Job** runs one batch task to completion. A **JobSet** orchestrates a *group of Jobs* as a single unit, which is what distributed batch systems (ML training, HPC, MPI) actually need.

JobSet is a Kubernetes SIG project (API group `jobset.x-k8s.io`). It is **not** built into Kubernetes — you install a controller and CRDs first.

## Job vs JobSet

| Aspect | Job (`batch/v1`) | JobSet (`jobset.x-k8s.io`) |
|---|---|---|
| Scope | One Job, N pods | Multiple Jobs managed together |
| Pod roles | All identical (or indexed) | Heterogeneous (e.g. leader + workers) |
| Coordination | None across jobs | Group-level success/failure policies |
| Networking | You add a Service manually | Auto headless Service + stable pod hostnames |
| Startup order | N/A | Can order replicated jobs |
| Built-in? | Yes | No (install CRD + controller) |
| Typical use | Single batch task | Distributed training, MPI, leader/worker |

Rule of thumb:

- One independent batch task → **Job**.
- Several related Jobs that must start, network, and succeed/fail together → **JobSet**.

## What JobSet Adds

- **ReplicatedJobs**: define Job templates and how many copies of each to create.
- **Cross-job success/failure policy**: e.g. the whole set succeeds when the leader finishes, or fails fast if any job fails.
- **Automatic headless Service**: pods get stable DNS hostnames so they can find each other (leader ↔ workers).
- **Startup ordering**: bring up a coordinator before workers.

## Install the JobSet Controller

JobSet ships as a CRD + controller (installed into the `jobset-system` namespace):

```bash
# Pin a released version (check the releases page for the latest)
kubectl apply --server-side -f \
  https://github.com/kubernetes-sigs/jobset/releases/download/v0.9.2/manifests.yaml

# Wait for the controller to be ready
kubectl wait --for=condition=Available deploy/jobset-controller-manager \
  -n jobset-system --timeout=120s

# Confirm the CRD is registered
kubectl get crd jobsets.jobset.x-k8s.io
```

## Example: Leader + 3 Workers

See [jobset-example.yaml](jobset-example.yaml). It defines two `replicatedJobs`:

- `leader`: a single coordinator Job.
- `workers`: an Indexed Job running 3 pods in parallel.

The `successPolicy` marks the whole JobSet complete once the `leader` Job succeeds.

```yaml
apiVersion: jobset.x-k8s.io/v1alpha2
kind: JobSet
metadata:
  name: dist-compute
spec:
  successPolicy:
    operator: All
    targetReplicatedJobs:
      - leader
  replicatedJobs:
    - name: leader
      replicas: 1
      template:
        spec:
          completions: 1
          parallelism: 1
          template:
            spec:
              restartPolicy: Never
              containers:
                - name: leader
                  image: busybox:1.36
                  command: ["/bin/sh", "-c"]
                  args: ["echo Leader on $(hostname); sleep 10; echo done"]
    - name: workers
      replicas: 1
      template:
        spec:
          completions: 3
          parallelism: 3
          completionMode: Indexed
          template:
            spec:
              restartPolicy: Never
              containers:
                - name: worker
                  image: busybox:1.36
                  command: ["/bin/sh", "-c"]
                  args: ["echo Worker $JOB_COMPLETION_INDEX on $(hostname); sleep 5"]
```

## Deploy and Monitor

```bash
kubectl apply -f jobset-example.yaml

# The JobSet object tracks overall state
kubectl get jobset dist-compute

# JobSet creates one Job per replicatedJob
kubectl get jobs -l jobset.sigs.k8s.io/jobset-name=dist-compute

# And the underlying pods
kubectl get pods -l jobset.sigs.k8s.io/jobset-name=dist-compute
```

## Verify Pod Hostnames and Networking

```bash
# JobSet auto-creates a headless Service for stable pod DNS
kubectl get svc -l jobset.sigs.k8s.io/jobset-name=dist-compute

# Inspect logs from a worker to see its index and hostname
POD=$(kubectl get pods -l jobset.sigs.k8s.io/replicatedjob-name=workers \
  -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD"
```

## Cleanup

```bash
kubectl delete -f jobset-example.yaml
```

Deleting the JobSet removes its child Jobs, pods, and the auto-created Service.

## Why JobSet Matters

- **Distributed ML training**: one driver + many workers that must start and finish together.
- **MPI / HPC**: rank-0 coordinator plus worker ranks with stable network identities.
- **All-or-nothing semantics**: the whole gang succeeds or fails as a unit, instead of orphaned half-finished Jobs.

## CKAD Note

Plain `Job` and `CronJob` are the exam-relevant, always-available primitives. JobSet is an advanced add-on (extra CRDs) — useful to understand conceptually, but not part of the default cluster.

- **In scope**: authoring `Job` (including `completionMode: Indexed`, `parallelism`, `completions`) and `CronJob`, plus headless Services for stable DNS.
- **Background only**: the `jobset.x-k8s.io` API (`replicatedJobs`, `successPolicy`, startup ordering) and its controller/CRD installation.
- Recognize that JobSet automates leader/worker coordination and networking that you'd otherwise assemble manually from Indexed Jobs and a headless Service.

## Key Takeaway

A JobSet orchestrates a group of Jobs (e.g. leader + workers) as a single unit with cross-job success/failure policies, automatic headless Service networking, and startup ordering — ideal for distributed training/HPC, but it's an add-on CRD beyond CKAD scope, where plain `Job` and `CronJob` are the primitives.

