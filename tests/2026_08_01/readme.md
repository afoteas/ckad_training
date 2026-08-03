# CKAD Simulation Exam — 2026-08-01

Exam #6 — **maximum difficulty**. Tasks use the same prose style as the live CKAD: a short business scenario, then an end-state description. Wording is deliberately indirect — you must infer the Kubernetes objects and fields yourself. **No commands are given.**

## Format

- **17 tasks, 120 minutes.** Weighted to the official CKAD domain split.
- Allowed docs (one browser tab): `kubernetes.io/docs`, `helm.sh/docs`, `kubectl.docs.kubernetes.io`. Nothing else.
- **Every task runs in a stated namespace.** Before each task, mentally run:

  ```
  kubectl config use-context kind-ckad
  ```

  Wrong namespace = zero points, even if the object spec is perfect.
- **Graded on the live cluster.** Unapplied YAML scores nothing. Verify with `kubectl get` / `describe`.
- Save manifests under `answers/` and record imperative work (Helm, Kustomize, debugging) in `answers/commands.md` or the file named in the task.
- Partial credit applies. Flag hard items and return later.

## Domain weighting

| Domain | Weight | Tasks |
|--------|-------:|-------|
| Application Design & Build | 20% | Q1–Q4 |
| Application Deployment | 20% | Q5–Q7 |
| App Environment, Config & Security | 25% | Q8–Q12 |
| Services & Networking | 20% | Q13–Q15 |
| Observability & Maintenance | 15% | Q16–Q17 |

## Setup

```bash
cd /home/foteas/code/ckad_training/tests/2026_08_01
bash setup.sh          # namespaces, seeded objects, kustomize base, local helm chart
bash setup.sh --reset   # tear down
```

## When finished

Say **"score my exam"** for a per-task and per-domain breakdown with pass/fail (pass = 66%).

---

# Tasks

## Application Design & Build (20%)

### Q1 [4%]
**Context.** Before an artefact is promoted, release engineering runs a one-shot integrity probe. The result must appear in the container logs, the process must finish cleanly, and the platform must not relaunch it afterward.
**Task.** In namespace `batch`, create a Pod named `integrity-gate` from image `busybox:1.36`. Feed the exact byte sequence `verify-me` on standard input with **no** trailing newline. Print the **MD5** digest to standard output and exit with status zero. Kubernetes must not restart the container once it has terminated.

### Q2 [6%]
**Context.** Two cooperating processes share a node-local scratch area. One appends timestamped lines to a log file; the other streams that file to its own stdout for collection. The streaming process must stay alive even if the log file does not exist when it first starts.
**Task.** In namespace `batch`, create a Pod named `dualproc` with containers `writer` and `forwarder` (both `busybox:1.36`) sharing a single ephemeral volume. `writer` appends the current date once per second to `/data/stream.log`. `forwarder` continuously emits the contents of that path on **its own** standard output. Both containers must run simultaneously.

### Q3 [5%]
**Context.** A backfill job must process eight units of work with no more than two workers at a time. Any single worker failure may be retried at most twice before the whole run is abandoned. If the run is still unfinished ninety seconds after it begins, the platform must cancel it entirely.
**Task.** In namespace `batch`, create a Job named `partition-ingest` using image `busybox:1.36` and any command that succeeds after a brief pause. The Job must reach **eight** successful completions with **two** concurrent workers, allow at most **two** retries before failing the Job, and enforce a **ninety-second** overall time limit from Job start.

### Q4 [5%]
**Context.** Housekeeping is triggered on a fixed five-minute cadence. A slow run must block the next trigger, and any slot that cannot start within twenty seconds of its scheduled time must be dropped — no catch-up runs.
**Task.** In namespace `batch`, create a CronJob named `janitor` (image `busybox:1.36`, any short successful command) scheduled **every five minutes**, with overlapping runs forbidden and a **twenty-second** starting deadline.

## Application Deployment (20%)

### Q5 [7%]
**Context.** The edge tier is delivered as a Helm chart from the public Bitnami repository (`https://charts.bitnami.com/bitnami`).
**Task.** In namespace `release`, install the Bitnami **nginx** chart as release `edge-proxy` so the workload runs exactly **2** replicas. Record what you ran in `answers/commands.md`.
*(If Bitnami is unreachable, a functionally equivalent chart is at `localchart/`.)*

### Q6 [7%]
**Context.** The same manifests are promoted through Kustomize; the live overlay must rename resources, scale out, and pin a newer image.
**Task.** A Kustomize base lives at `kustomize/base` (Deployment `api`). Under `answers/kustomize/live`, create an overlay that (a) prepends `live-` to all produced resource names, (b) runs **5** replicas, and (c) sets the container image to `nginx:1.27`. Apply the overlay into namespace `release`. Record the apply command in `answers/commands.md`.

### Q7 [6%]
**Context.** Checkout traffic is load-balanced across every pod carrying `component=checkout`. A new revision should take roughly one third of that traffic without touching the Service front door.
**Task.** In namespace `release`, Deployment `checkout-stable` and Service `checkout` already exist. Introduce Deployment `checkout-next` using image `nginx:1.27` whose pods are also selected by `checkout`. Size replicas so approximately **33%** of traffic reaches the new revision. You must **not** modify Service `checkout`.

## App Environment, Config & Security (25%)

### Q8 [5%]
**Context.** Operational toggles are stored under one set of keys but consumed by the application under different environment variable names.
**Task.** In namespace `settings`, create ConfigMap `runtime-toggles` with `log_level=debug` and `shard=us-east-1`. Create a long-running Pod `toggle-reader` (`busybox:1.36`) that exposes `log_level` as environment variable `LOG_LEVEL` and `shard` as environment variable `SHARD_ID`.

### Q9 [5%]
**Context.** A workload needs the same credential on disk and in the process environment.
**Task.** In namespace `settings`, create Secret `vault-token` containing `credential=hunter2`. Create Pod `token-consumer` (`nginx:1.25`) that mounts the Secret **read-only** at `/var/run/secrets` and also injects `credential` as environment variable `VAULT_CRED`.

### Q10 [7%]
**Context.** A compliance scanner must observe Pods across the entire cluster, but may only inspect ConfigMaps inside its own namespace.
**Task.** In namespace `identity`, create ServiceAccount `auditor`. Define ClusterRole `pod-watcher` granting cluster-wide `get`, `list`, and `watch` on `pods`. Define Role `cm-reader` in namespace `identity` granting `get` and `list` on `configmaps`. Bind both roles to the ServiceAccount (use any binding names you like). Run Pod `auditor-agent` (`nginx:1.25`) in `identity` using that ServiceAccount.

### Q11 [4%]
**Context.** A security baseline mandates non-root execution, no privilege escalation, all Linux capabilities stripped, an immutable root filesystem, and a writable scratch area for temporary files.
**Task.** In namespace `hardened`, create a long-running Pod named `hardened` (`busybox:1.36`) running as UID **2000**, with all requirements above satisfied. Mount a writable ephemeral volume at `/tmp/work`. The Pod must reach **Running**.

### Q12 [4%]
**Context.** Namespace `quota` applies default container resource policies; workloads must still declare their own footprint explicitly.
**Task.** In namespace `quota`, create a long-running Pod named `compute` (`busybox:1.36`) that **requests** 128Mi memory and 200m CPU and is **limited** to 256Mi memory and 500m CPU. The Pod must be **Running**.

## Services & Networking (20%)

### Q13 [4%]
**Context.** Message brokers need per-pod DNS records instead of a single cluster virtual IP.
**Task.** In namespace `mesh`, Deployment `broker` (pods labeled `app=broker`) already exists. Create a **headless** Service named `broker-peers` targeting those pods on port **9092**.

### Q14 [7%]
**Context.** External clients must reach the shop API at `api.shop.internal` over HTTPS on path `/v1`.
**Task.** In namespace `mesh`, Deployment `shop-api`, Service `shop-api` (port **8080**), and TLS Secret `shop-tls` already exist. Create Ingress `shop-front` with ingress class `nginx` routing host `api.shop.internal`, path `/v1` (Prefix), to Service `shop-api` on port **8080**, terminating TLS with `shop-tls`.

### Q15 [9%]
**Context.** A service mesh policy requires default-deny ingress for every workload in the namespace. The only exception: pods labeled `role=frontend` may reach pods labeled `role=backend` on TCP port **8080** — nothing else.
**Task.** In namespace `mesh`, first ensure **no** pod accepts ingress traffic unless explicitly allowed. Then permit the frontend→backend path described above and **only** that path. Name the policies `mesh-deny-all` and `mesh-allow-front-to-back`.

## Observability & Maintenance (15%)

### Q16 [6%]
**Context.** A freshly deployed API never becomes available; replicas stay unready although the container image is correct.
**Task.** In namespace `triage`, Deployment `miswired` was applied but is not reaching a ready state. Diagnose and repair it so all replicas run — **without** changing the container image or the names of any environment variables the application expects. Record root cause and fix in `answers/commands.md`.

### Q17 [4%]
**Context.** A singleton process keeps restarting seconds after launch.
**Task.** In namespace `triage`, Pod `flapper` is not stable. In `answers/q17.txt`, line 1: the failure reason **as Kubernetes reports it**; line 2: the command you used to discover it. Then correct the Pod so it runs successfully.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q4, Q8–Q15 (manifests) | `answers/qNN.yaml` |
| Q5, Q6, Q7, Q16 (imperative/debug) | `answers/commands.md` |
| Q6 overlay | `answers/kustomize/live/` + apply command in `commands.md` |
| Q17 | `answers/q17.txt` (+ fix applied live) |

## Suggested time budget

| Phase | Min |
|-------|----:|
| Skim + flag all tasks | 5 |
| Design & Build (Q1–4) | 22 |
| Deployment (Q5–7) | 24 |
| Config & Security (Q8–12) | 32 |
| Networking (Q13–15) | 28 |
| Observability (Q16–17) | 9 |
| Review flagged | 5 |
