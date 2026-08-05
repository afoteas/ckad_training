# CKAD Simulation Exam — 2026-07-31

Exam #5 — a full CKAD simulator. Tasks are written the way the real exam writes them: a short **scenario**, then a **Task** that states the required end state in prose. **No commands are given** — you decide how to achieve each result. Precise names, namespaces, ports and values are what get graded, so read carefully.

## Format

- **17 tasks, 120 minutes.** Weighted to the official CKAD domain split.
- Allowed docs (one browser tab): `kubernetes.io/docs`, `helm.sh/docs`, `kubectl.docs.kubernetes.io`. Nothing else.
- **Every task runs in a stated namespace.** On the real exam each item begins by telling you to switch context; here, before each task, mentally run:

  ```
  kubectl config use-context kind-ckad
  ```

  and always target the task's namespace. Creating the right object in the wrong namespace scores 0.
- **You are graded on the live cluster.** Manifests that aren't applied score nothing. Verify with `kubectl get` / `describe`. Pods are immutable — recreate them to change spec.
- Save your manifests under `answers/` and record any non-manifest work (Helm, Kustomize, debugging, one-line commands) in `answers/commands.md` / the stated answer file.
- Partial credit applies. Flag hard items and come back.

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
cd /home/foteas/code/ckad_training/tests/2026_07_31
bash setup.sh          # namespaces, seeded objects, kustomize base, local helm chart
bash setup.sh --reset   # tear down
```

## When finished

Say **"score my exam"** for a per-task and per-domain breakdown with pass/fail (pass = 66%).

---

# Tasks

## Application Design & Build (20%)

### Q1 [4%]
**Context.** The data team needs a throwaway pod that emits a checksum during a pipeline dry-run.
**Task.** In namespace `workloads`, create a Pod named `checksum` from image `busybox:1.36`. The container must compute the SHA-256 digest of the exact string `ckad` (the string fed on standard input, with no trailing newline) and then exit. The Pod must complete successfully and must **not** be restarted by Kubernetes.

### Q2 [6%]
**Context.** A legacy application only writes its access log to a file on disk; a companion process must stream that log so the platform can collect it.
**Task.** In namespace `workloads`, create a Pod named `logshipper` whose two containers share a single ephemeral volume:
- the primary container `app` (`busybox:1.36`) appends a line containing the current date to `/var/log/app/access.log` roughly once per second, indefinitely;
- the companion container `shipper` (`busybox:1.36`) continuously emits the contents of that same file to **its own** standard output, and must keep working even if the file does not exist at the moment it starts.
Both containers must be running simultaneously.

### Q3 [5%]
**Context.** An overnight import must process exactly ten records, a few at a time, and must be abandoned if the whole batch runs too long.
**Task.** In namespace `workloads`, create a Job named `import` using image `busybox:1.36` and any command that succeeds after a short delay. The batch must run to **ten** successful completions, with **three** pods executing concurrently, and the entire Job must be terminated automatically if it is still running **60 seconds** after it started.

### Q4 [5%]
**Context.** A housekeeping routine runs frequently, but a slow run must never overlap the next, and the system must not try to catch up on runs it missed while the cluster was busy.
**Task.** In namespace `workloads`, create a CronJob named `cleanup` (image `busybox:1.36`, any brief command) that triggers **every 10 minutes**, refuses to start a new run while a previous one is still active, and gives up on any scheduled run that cannot begin within **30 seconds** of its scheduled time.

## Application Deployment (20%)

### Q5 [7%]
**Context.** The web tier is shipped to teams as a Helm chart from the public Bitnami repository (`https://charts.bitnami.com/bitnami`).
**Task.** In namespace `deploy`, use Helm to install the Bitnami **apache** chart as a release named `webtier`, configured so that the workload runs **3 replicas**. Record what you ran in `commands.md`.
*(If your network blocks the Bitnami repository, a functionally equivalent chart is provided at `localchart/`; using it is an acceptable fallback.)*

### Q6 [7%]
**Context.** The same base manifests are promoted to a production environment with environment-specific changes, managed with Kustomize.
**Task.** A Kustomize base is provided at `kustomize/base` (it defines a Deployment named `frontend`). Under `answers/kustomize/prod`, create an overlay that (a) prepends the prefix `prod-` to the names of all resources it produces, (b) makes the workload run **4 replicas**, and (c) pins the container image to `nginx:1.27`. Apply the overlay into namespace `deploy`. Record the apply command in `commands.md`.

### Q7 [6%]
**Context.** A new version of the payment service is being rolled out as a canary that should receive roughly a quarter of the traffic. Traffic is distributed by an existing Service across every pod carrying the label `app=payment`.
**Task.** In namespace `deploy`, a Deployment `payment-v1` and a Service `payment` already exist. Introduce the canary by creating a Deployment named `payment-v2` that uses image `nginx:1.27`, whose pods are also served by the existing `payment` Service. Choose replica counts for the two Deployments so that approximately **25%** of traffic reaches the canary. You must **not** modify the Service.

## App Environment, Config & Security (25%)

### Q8 [5%]
**Context.** An application reads two settings from environment variables whose names deliberately differ from the configuration keys.
**Task.** In namespace `config`, create a ConfigMap named `runtime` holding `verbosity=high` and `region=eu-west`. Then create a long-running Pod named `envmap` (`busybox:1.36`) that surfaces the value of the `verbosity` key as an environment variable called `LOG_VERBOSITY`, and the value of the `region` key as an environment variable called `DEPLOY_REGION`.

### Q9 [5%]
**Context.** A service needs its API token both on disk and in the environment.
**Task.** In namespace `config`, create a Secret named `apicreds` containing `token=abc123xyz`. Create a Pod named `creduser` (`nginx:1.25`) that mounts this Secret **read-only** at `/etc/creds`, and additionally exposes the `token` value as an environment variable named `API_TOKEN`.

### Q10 [7%]
**Context.** A monitoring agent must be able to read node and pod information across the entire cluster, using its own identity.
**Task.** In namespace `rbac`, create a ServiceAccount named `monitor`. Grant that identity cluster-wide permission to `get`, `list` and `watch` the resources `nodes` and `pods` (define a ClusterRole named `cluster-reader` and bind it to the ServiceAccount). Finally, run a Pod named `agent` (`nginx:1.25`) in namespace `rbac` that acts as the `monitor` ServiceAccount.

### Q11 [4%]
**Context.** Security policy demands a fully locked-down container.
**Task.** In namespace `secure`, create a long-running Pod named `fortress` (`busybox:1.36`) that runs as user ID `1000`, is forbidden from gaining additional privileges, has **all** Linux capabilities removed, and runs with an **immutable (read-only) root filesystem**. Because the root filesystem is read-only, provide a writable ephemeral volume mounted at `/scratch`. The Pod must reach the Running state.

### Q12 [4%]
**Context.** The `limits` namespace enforces default container limits; a new workload must declare its own resource footprint.
**Task.** In namespace `limits`, create a long-running Pod named `worker` (`busybox:1.36`) whose container **requests** 64Mi of memory and 100m CPU, and is **limited** to 128Mi of memory and 250m CPU. The Pod must be Running.

## Services & Networking (20%)

### Q13 [4%]
**Context.** A cache tier needs stable network identity rather than a single virtual IP.
**Task.** In namespace `net`, a Deployment `cache` (pods labeled `app=cache`) already exists. Create a **headless** Service named `cache-hs` that targets those pods on port `6379`.

### Q14 [7%]
**Context.** The public website must be served over HTTPS at a vanity hostname.
**Task.** In namespace `net`, a Deployment `secure-site` and a Service `secure-site` (port `80`) already exist, and a TLS Secret named `site-tls` has been provisioned for you. Create an Ingress named `site-tls-ing` using ingress class `nginx` that routes host `www.example.com`, path `/` (Prefix), to the `secure-site` Service on port `80`, and terminates TLS for `www.example.com` using the `site-tls` Secret.

### Q15 [9%]
**Context.** The database tier is currently reachable by anything in its namespace. Security requires a strict posture: nothing may reach any pod unless explicitly allowed, and the database may only be reached by the API tier on its database port.
**Task.** In namespace `net`, first make it so that, by default, **no** ingress traffic is permitted to **any** pod in the namespace. Then, in addition, allow pods labeled `app=db` to receive ingress traffic **exclusively** from pods labeled `tier=api` in the same namespace, and **only** on TCP port `5432`. Name the default-deny policy `default-deny-ingress` and the allow policy `db-allow-api`.

## Observability & Maintenance (15%)

### Q16 [6%]
**Context.** A newly rolled-out service is stuck; its pods never reach a running state.
**Task.** In namespace `observe`, the Deployment `broken-cfg` was applied but is not becoming available. Determine why and fix it so that all replicas run — **without** altering the container image or the environment-variable names the application expects. Record the root cause and the fix you applied in `commands.md`.

### Q17 [4%]
**Context.** A single pod refuses to start shortly after being created.
**Task.** In namespace `observe`, the Pod `bad-image` is not running. In `answers/q17.txt`, write on line 1 the failure reason **as Kubernetes reports it**, and on line 2 the command you used to discover it. Then correct the Pod so that it runs successfully.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q4, Q8–Q15 (manifests) | `answers/qNN.yaml` |
| Q5, Q7, Q16 (imperative/debug) | `answers/commands.md` |
| Q6 overlay | `answers/kustomize/prod/` + apply command in `commands.md` |
| Q17 | `answers/q17.txt` (+ fix applied live) |

## Suggested time budget

| Phase | Min |
|-------|----:|
| Read + flag all | 5 |
| Design & Build (Q1–4) | 20 |
| Deployment (Q5–7) | 25 |
| Config & Security (Q8–12) | 30 |
| Networking (Q13–15) | 25 |
| Observability (Q16–17) | 10 |
| Review flagged | 5 |
