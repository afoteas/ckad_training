# CKAD Practice Exam — 2026-07-28

A fresh timed CKAD-style mock. **16 tasks, weighted, 2 hours.** Different tasks from the 07-27 set — this round adds init containers, securityContext, ConfigMap-as-volume, Secret via `envFrom`, exec/startup probes, Ingress, and an egress NetworkPolicy. Work against your local `kind` cluster (context `kind-ckad`).

## Rules (mirror the real exam)

- Time limit: **120 minutes**. Set a timer.
- One `kubernetes.io/docs` tab allowed. No other help.
- Every task states its **namespace** — create it if missing, and put the object there.
- Write answers under `answers/` (one file per task, e.g. `answers/q01.yaml`). For imperative/live tasks, record the exact commands in `answers/commands.md`.
- **Read each task fully** — mount paths, probe timings, and multi-part sub-requirements are where points are lost.
- Partial credit exists. Skip and return; do not get stuck.

## Setup

Run once before starting the clock. Creates the pre-existing objects that "fix it" / dependent tasks need.

```bash
cd /home/foteas/code/ckad_training/playground/2026_07_28
bash setup.sh
```

Reset between attempts:

```bash
bash setup.sh --reset   # deletes exam namespaces, then recreates
```

## How scoring works

When done, tell me **"score my exam"**. I will read your `answers/` files, inspect live cluster state, check each task's required spec, and give a per-task breakdown, total %, and pass/fail (pass = 66%).

---

## Tasks

Weights in **[ ]**. Namespaces are stated per task.

### Q1 — Deployment + scale [5%]
Namespace `app-deploy`. Create a Deployment `api` (image `nginx:1.25`, `2` replicas, container port `80`, pod label `app=api`). Then **scale it to 5 replicas** (record how you did it in `commands.md`).

### Q2 — Rollout with change-cause + rollback [6%]
Namespace `app-deploy`. On `api`:
- update the image to `nginx:1.27` **and record the change-cause** (history must show it, not `<none>`).
- Confirm the rollout succeeded, then **roll back** to the `nginx:1.25` revision.

### Q3 — Init container [7%]
Namespace `app-deploy`. Create a Pod `init-demo`:
- an **initContainer** `setup` (`busybox:1.36`) that runs `sh -c "echo ready > /work/status"`
- a main container `app` (`busybox:1.36`, `sh -c "cat /work/status && sleep 3600"`)
- both share an `emptyDir` volume `work` mounted at `/work`.

### Q4 — ConfigMap as a mounted volume [6%]
Namespace `app-config`.
- Create a ConfigMap `web-config` from two literals: `index.html=Hello CKAD` and `mode=prod`.
- Create a Pod `cm-volume` (image `nginx:1.25`) that mounts `web-config` as a **volume** at `/etc/web` (not as env vars).

### Q5 — Secret via envFrom [6%]
Namespace `app-config`.
- Create a generic Secret `api-creds` with `API_KEY=abc123` and `API_USER=admin`.
- Create a Deployment `env-app` (image `busybox:1.36`, `sh -c "sleep 3600"`, 1 replica) that injects **all** keys of `api-creds` as environment variables using `envFrom`.

### Q6 — securityContext [6%]
Namespace `app-secure`. Create a Pod `secure-pod` (image `busybox:1.36`, `sh -c "sleep 3600"`) that:
- runs as **non-root**, user ID `1000`, group ID `3000`
- sets `fsGroup: 2000`
- the container drops **all** Linux capabilities.

### Q7 — Resources on existing Deployment [5%]
Namespace `app-secure`. A Deployment `resource-app` exists (created by setup). Set its container resources to:
- requests `cpu=100m`, `memory=128Mi`
- limits `cpu=300m`, `memory=256Mi`

(Do it however you like; if imperative, log it in `commands.md`.)

### Q8 — Exec + startup probes [7%]
Namespace `app-health`. Create a Deployment `checker` (image `busybox:1.36`, 1 replica, command `sh -c "touch /tmp/healthy && sleep 3600"`) with:
- a **liveness** probe: `exec` running `cat /tmp/healthy`, initialDelay `5s`, period `10s`
- a **startup** probe: `exec` running `cat /tmp/healthy`, `failureThreshold: 10`, period `5s`.

### Q9 — Debug a CrashLoopBackOff [7%]
Namespace `app-health`. A Deployment `crashy` exists (created by setup) whose pods are in **CrashLoopBackOff**. Diagnose and fix it in place so all pods are `Running` and stay up. Do **not** delete the Deployment. Record what was wrong and your fix in `commands.md`.

### Q10 — CronJob (suspend + history limits) [6%]
Namespace `app-batch`. Create a CronJob `report`:
- schedule every 10 minutes (`*/10 * * * *`)
- image `busybox:1.36`, command `sh -c "echo report generated"`
- `restartPolicy: OnFailure`
- `concurrencyPolicy: Forbid`
- keep `successfulJobsHistoryLimit: 2` and `failedJobsHistoryLimit: 1`.

### Q11 — Parallel Job [6%]
Namespace `app-batch`. Create a Job `crunch`:
- image `busybox:1.36`, command `sh -c "echo processing; sleep 5"`
- `completions: 4`, `parallelism: 2`, `backoffLimit: 3`.
- It must finish with 4 successful completions.

### Q12 — Sidecar logging (Deployment) [6%]
Namespace `app-design`. Create a Deployment `logger` (1 replica) with two containers sharing an `emptyDir` `varlog` at `/var/log/app`:
- `app`: `busybox:1.36`, `sh -c "while true; do echo hit >> /var/log/app/access.log; sleep 3; done"`
- `sidecar`: `busybox:1.36`, `sh -c "tail -f /var/log/app/access.log"`.

### Q13 — Headless Service [5%]
Namespace `app-net`. The `api` Deployment's pods (label `app=api`) exist here too (setup creates a copy). Create a **headless** Service `api-headless`:
- `clusterIP: None`
- port `80` → targetPort `80`
- selects `app=api`.

### Q14 — Ingress [8%]
Namespace `app-ingress`. Setup created a Deployment `site` and a ClusterIP Service `site` (port `80`). Create an Ingress `site-ingress`:
- host `site.example.com`
- path `/` (pathType `Prefix`) → service `site` port `80`
- ingressClassName `nginx`.

### Q15 — Egress NetworkPolicy [8%]
Namespace `app-net`. Setup created pods `frontend` (label `app=frontend`) and `db` (label `app=db`, Service `db`). Create a NetworkPolicy `frontend-egress` that:
- applies to pods labeled `app=frontend`
- allows **egress** only to pods labeled `app=db` on port `3306`
- also allows egress to **DNS** (UDP `53`) so name resolution still works
- denies all other egress.

### Q16 — Observability [6%]
Namespace `app-health`. From the `checker` Deployment (Q8):
- write the **name of any running pod** into `answers/q16.txt` (line 1)
- on line 2, write the **command** you used to view that pod's logs
- on line 3, write the container's **restart count**.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q15 (manifests) | `answers/qNN.yaml` |
| Imperative/live commands | `answers/commands.md` (label per task) |
| Q16 | `answers/q16.txt` |

Apply everything to the **live cluster** too — scoring inspects both your files and the cluster.

## Time budget suggestion

| Phase | Minutes |
|-------|---------|
| Read + flag all tasks | 5 |
| Easy wins (Q1, Q4, Q10, Q11, Q13) | 30 |
| Medium (Q3, Q5, Q6, Q8, Q12, Q14) | 50 |
| Hard / debug (Q2, Q7, Q9, Q15, Q16) | 30 |
| Review flagged | 5 |
