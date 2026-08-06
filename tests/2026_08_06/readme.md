# CKAD Simulation Exam — 2026-08-06

Exam #8 — **final dress rehearsal**, the night before the real thing.

Unlike Exam #7 (gap-fill), this one is deliberately **high-frequency**: it drills the object
types and fields that actually dominate the live CKAD, in roughly the proportion you will
meet them. Nothing exotic. If you can clear this inside the time box, you are ready.

Wording is indirect, as on the real exam — a short business context, then an end state.
**No commands are given.** You infer the objects and fields.

## Format

- **17 tasks, 120 minutes.** Official CKAD domain weights.
- Allowed docs (one browser tab): `kubernetes.io/docs`, `helm.sh/docs`, `kubectl.docs.kubernetes.io`.
- **Every task names a namespace.** Read it twice. Wrong namespace scores zero even with a perfect spec.
- **Graded on the live cluster.** Unapplied YAML is worth nothing.
- Save manifests under `answers/`; record imperative work in `answers/commands.md` or the file named in the task.
- Partial credit applies. Flag anything that costs more than ~8 minutes and come back to it.

## Setup

```bash
cd /home/foteas/code/ckad_training/tests/2026_08_06
bash setup.sh           # namespaces, seeded objects, kustomize base, local helm chart
bash setup.sh --reset   # tear down
```

The script refuses to run if the cluster is unreachable and tells you how to bring it back.

## Scoring

```bash
bash verify.sh          # machine-scored, per-task and per-domain, pass = 66%
bash verify.sh -q       # only the checks you failed
```

You can also say **"score my exam"** for a written review of your manifests and approach.

## Exam-day reflexes

Set these up in the first 60 seconds of the real exam, then forget about them:

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
```

Generate, never hand-write: `k run`, `k create deploy`, `k create job`, `k create cronjob`,
`k expose`, `k create role|rolebinding|sa|cm|secret`, `k set image`, `k scale`.
For everything the generators cannot reach — probes, volumes, securityContext, affinity —
`k explain --recursive` beats searching the docs site.

---

# Tasks

## Application Design & Build (20%)

### Q1 [4%]
**Context.** A nightly integrity sweep processes six independent shards. Operations wants three
shards in flight at once, tolerates a couple of individual failures before declaring the sweep
dead, and hard-stops the whole sweep if it is still running after two minutes. Finished sweeps
must not linger in the cluster indefinitely — they clear themselves out after two hours.

**Task.** In namespace `batch`, create a Job named `integrity-sweep` from image `busybox:1.36`
running any command that succeeds after a brief pause. It must reach **six** successful
completions with **three** running concurrently, permit at most **two** retries before the Job
is considered failed, abort after **120 seconds** from start, and have its object garbage
collected **7200 seconds** after finishing. A failed container must not be restarted in place.

### Q2 [6%]
**Context.** An application writes its audit trail to a file on a node-local scratch area. A
companion process must stream that file to its own stdout so the cluster log collector picks it
up. The companion must be running *before* the application starts, must stay up for the whole
life of the Pod, and must not keep the Pod alive on its own.

**Task.** In namespace `batch`, create a Pod named `audit-stream` with an application container
named `app` and a companion named `shipper`, both `busybox:1.36`, sharing one ephemeral volume
mounted at `/var/log/audit`. `app` appends the current date to `/var/log/audit/trail.log` once
per second. `shipper` continuously emits that file's contents on **its own** stdout. Implement
`shipper` as a **sidecar** in the Kubernetes-native sense — not as a second ordinary container.

### Q3 [5%]
**Context.** A reporting tool must keep its output across Pod restarts. Storage is pre-provisioned
by hand on this cluster; there is no dynamic provisioner for the class in question.

**Task.** In namespace `storage`, create a PersistentVolume `archive-pv` of **1Gi**, access mode
**ReadWriteOnce**, storage class name `manual`, backed by host path `/mnt/archive`. Create a
PersistentVolumeClaim `archive-pvc` requesting **500Mi** from that same class, and confirm it
binds. Then run a long-lived Pod `archive-writer` (`busybox:1.36`) that mounts the claim at
`/var/archive`.

### Q4 [5%]
**Context.** A report is regenerated on a fixed two-minute cadence. A slow run must block the
next trigger rather than run alongside it, a slot that cannot start within fifteen seconds of
its scheduled time is dropped, and an individual run that exceeds thirty seconds is killed. Only
a short tail of run history is kept.

**Task.** In namespace `batch`, create a CronJob named `report-gen` (image `busybox:1.36`, any
short successful command) with all of the above: schedule **every two minutes**, overlapping runs
**forbidden**, **15-second** starting deadline, **30-second** per-run time limit, and history
limits of **2** successful and **1** failed Job. A failed container should be restarted in place.

## Application Deployment (20%)

### Q5 [6%]
**Context.** The public entry point is shipped as a Helm chart. It must go out at three replicas
on a newer image than the chart default, and the chart itself is read-only — overrides only.

**Task.** In namespace `release`, install the chart in `localchart/` as release `frontdoor` so the
workload runs **3** replicas with image **`nginx:1.27`**. Do not edit any file inside `localchart/`.
Record the command you ran, plus the output of a command that lists the release, in
`answers/commands.md`.

### Q6 [7%]
**Context.** The same base manifests are promoted to production through Kustomize. Production
renames every object it produces, tags them for cost reporting, scales out, and pins a newer image.

**Task.** A Kustomize base lives at `kustomize/base` (Deployment `api`). Under
`answers/kustomize/prod`, build an overlay that prefixes every produced name with `prod-`, adds
the label `env=prod` to everything it produces, runs **4** replicas, and sets the container image
to `nginx:1.27`. Apply it into namespace `release`. Record the apply command in
`answers/commands.md`.

### Q7 [7%]
**Context.** Payments must never lose capacity during a rollout — the update may temporarily run
hot, but not thin. Separately, the change currently sitting at the head of the rollout history is
broken and the tier is stuck part-way through it. The last good build must serve again.

**Task.** In namespace `release`, Deployment `payments` exists. Configure its update strategy so a
rollout may run up to **two extra** Pods but **zero** Pods below the desired count. Then return the
workload to the most recent revision that actually starts, so all **3** replicas are Running and
up to date. Record how you identified the good revision in `answers/commands.md`.

## Application Environment, Configuration & Security (25%)

### Q8 [5%]
**Context.** A service reads its whole operational profile from the environment, and separately
needs the same values on disk for a config-reload watcher.

**Task.** In namespace `settings`, create ConfigMap `app-settings` with `log_level=warn`,
`region=eu-west-1`, and `feature_flags=beta,metrics`. Create a long-running Pod `settings-reader`
(`busybox:1.36`) that receives **all three keys as environment variables in one shot** (not key by
key) and also mounts the same ConfigMap as files under `/etc/app-settings`.

### Q9 [4%]
**Context.** A credential must reach the process environment under names the application already
expects. The workload never talks to the Kubernetes API, so its API credential should not be
projected into it at all.

**Task.** In namespace `settings`, create Secret `api-creds` with `username=svc-portal` and
`password=Tr0ub4dor`. Create Pod `creds-user` (`nginx:1.25`) exposing `username` as `APP_USER` and
`password` as `APP_PASS`, with the ServiceAccount token **not** mounted.

### Q10 [6%]
**Context.** A release bot needs to manage Deployments in its own namespace and observe the Pods
they create — nothing beyond that, and nowhere else.

**Task.** In namespace `access`, create ServiceAccount `deploy-bot`. Grant it, **within that
namespace only**, `get`/`list`/`watch`/`create`/`update`/`patch` on `deployments` and `get`/`list`
on `pods`, using a Role named `deploy-manager` and a RoleBinding named `deploy-bot-binding`. Run a
long-lived Pod `bot` (`nginx:1.25`) under that identity. In `answers/commands.md`, record a command
proving the bot **can** create Deployments in `access` and **cannot** delete them.

### Q11 [5%]
**Context.** A hardening baseline: the process runs as an unprivileged fixed identity, cannot gain
new privileges, holds no Linux capabilities, and cannot write to its own image. It still needs
somewhere to write temporary state, group-owned by its supplementary group.

**Task.** In namespace `hardened`, create a long-running Pod `vault-agent` (`busybox:1.36`) running
as UID **3000**, GID **4000**, with supplemental group **5000** applied to mounted volumes, with
privilege escalation disabled, **all** capabilities dropped, and a read-only root filesystem. Give
it a writable ephemeral volume at `/data`. The Pod must reach **Running**. Save the output of `id`
run inside the container to `answers/q11-id.txt`.

### Q12 [5%]
**Context.** A tenant namespace is capped before workloads are admitted, and every workload must
declare a footprint that fits inside the cap.

**Task.** In namespace `capacity`, create ResourceQuota `team-quota` allowing at most **5** Pods,
**1** CPU and **1Gi** memory of aggregate *requests*, and **2** CPU and **2Gi** memory of aggregate
*limits*. Then create Deployment `sizer` (`nginx:1.25`, **2** replicas) whose containers request
`200m` CPU / `128Mi` memory and are limited to `400m` CPU / `256Mi` memory. Both replicas must
become Running.

## Services & Networking (20%)

### Q13 [4%]
**Context.** An internal tier is reached by other Pods on a port that differs from the one the
container actually listens on. No external exposure.

**Task.** In namespace `edge`, Deployment `web-tier` already exists (Pods labeled `app=web-tier`,
container listening on **80**). Expose it with a cluster-internal Service named `web-tier-svc`
accepting traffic on port **8080** and forwarding to container port **80**. Prove it works from a
temporary Pod inside the cluster and save the response to `answers/q13-curl.txt`.

### Q14 [7%]
**Context.** One hostname fronts two backends: the storefront serves everything, except calls
under `/api`, which belong to the API tier.

**Task.** In namespace `edge`, Services `shop-ui` (port **80**) and `shop-api` (port **8080**)
already exist. Create Ingress `shop` with ingress class `nginx` for host `shop.internal` routing
prefix path `/api` to `shop-api:8080` and prefix path `/` to `shop-ui:80`.

### Q15 [9%]
**Context.** Zero-trust inside the namespace: nothing accepts traffic unless a policy says so.
The single exception is the API tier, which may be reached on its application port by the local
frontend Pods and by anything running in the operations tooling namespace — and by nothing else.

**Task.** In namespace `mesh`, first ensure **no** Pod accepts ingress traffic (policy
`mesh-default-deny`). Then allow ingress to Pods labeled `app=api` on TCP **8080** from Pods
labeled `tier=frontend` **in `mesh`**, and from **all** Pods in namespaces labeled `team=ops`
(policy `mesh-allow-api`). Namespace `ops-tools` carries that label. Nothing else may reach the
API tier.

## Observability & Maintenance (15%)

### Q16 [8%]
**Context.** A slow-booting catalog service is being restarted by the platform before it finishes
loading, and traffic is sent to it before it is ready. It also needs an ongoing liveness signal
that does not depend on the network stack.

**Task.** In namespace `triage`, Deployment `catalog` runs without any health checking. Add all
three probe types to its container:

- a **startup** check on HTTP `GET /` port **80**, polling every **2s**, allowing up to **30**
  consecutive failures before giving up;
- a **readiness** check on HTTP `GET /` port **80**, first checked after **3s**, every **5s**;
- a **liveness** check that runs a **command inside the container** verifying
  `/usr/share/nginx/html/index.html` exists, every **10s**.

All replicas must end up Ready.

### Q17 [7%]
**Context.** Three Pods in one namespace are all broken, each for a different reason. Triage is
graded on naming the reason exactly as Kubernetes reports it, not on prose.

**Task.** In namespace `triage`, Pods `alpha`, `beta` and `gamma` are all failing. In
`answers/q17.txt` write **one line per Pod** in the form `<pod> <reason>`, where `<reason>` is the
status/waiting reason **as Kubernetes reports it**. Then repair all three so each reaches a healthy
state, changing as little as possible. Record the command you used to diagnose them in
`answers/commands.md`.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q4, Q8–Q9, Q11–Q15 (manifests) | `answers/qNN.yaml` |
| Q5, Q6, Q7, Q10, Q17 (imperative / debug) | `answers/commands.md` |
| Q6 overlay | `answers/kustomize/prod/` |
| Q11 | `answers/q11-id.txt` |
| Q13 | `answers/q13-curl.txt` |
| Q17 | `answers/q17.txt` |

## Suggested time budget

| Phase | Min |
|-------|----:|
| Aliases + skim + flag all tasks | 6 |
| Design & Build (Q1–Q4) | 22 |
| Deployment (Q5–Q7) | 22 |
| Config & Security (Q8–Q12) | 30 |
| Networking (Q13–Q15) | 24 |
| Observability (Q16–Q17) | 12 |
| Review flagged | 4 |

## Local-cluster caveats

- **NetworkPolicy (Q15) is not enforced by kindnet.** The policy objects are graded on their spec,
  which is exactly how the real exam grades them too. Do not waste time trying to prove a drop.
- **Ingress (Q14)** is graded on the object. You only need a running ingress-nginx controller if
  you want to curl it.
- Q2 needs native sidecar support. `kind-ckad` is on **v1.31.0**, so you are fine.
- `verify.sh` scores **4.90%** on an untouched exam — a handful of checks describe facts the seed
  already satisfies (`payments` has 3 Ready replicas, `catalog` has 2, the chart is unedited) plus
  three RBAC "must not be able to" assertions that hold trivially while the ServiceAccount is
  absent. Treat 4.90% as your zero.
