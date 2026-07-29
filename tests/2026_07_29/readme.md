# CKAD Practice Exam — 2026-07-29

Exam #3. **16 tasks, weighted, 2 hours.** New topics this round: `subPath` mounts, ResourceQuota, node scheduling (nodeSelector/affinity), Ingress **TLS**, a `namespaceSelector` NetworkPolicy, and a **Pending-pod** debug. Work against your local `kind` cluster (context `kind-ckad`).

## Rules (mirror the real exam)

- Time limit: **120 minutes**. Set a timer.
- One `kubernetes.io/docs` tab allowed. No other help.
- Every task states its **namespace** — create it if missing, and put the object there.
- Write answers under `answers/` (one file per task, e.g. `answers/q01.yaml`). For imperative/live tasks, record the exact commands in `answers/commands.md`.
- **APPLY everything to the live cluster and VERIFY** — a correct file that isn't applied scores 0. For Pods, remember editing needs delete/recreate (`kubectl replace --force`).
- **Read exact values** — mount paths, probe timings, ports, labels. That's where points leak.
- Partial credit exists. Skip and return; don't get stuck.

## Setup

Run once before starting the clock.

```bash
cd /home/foteas/code/ckad_training/tests/2026_07_29
bash setup.sh
```

Reset between attempts:

```bash
bash setup.sh --reset
```

## How scoring works

When done, tell me **"score my exam"**. I read your `answers/` files, inspect live cluster state, check each task's spec, and give a per-task breakdown, total %, and pass/fail (pass = 66%).

---

## Tasks

Weights in **[ ]**. Namespaces are stated per task.

### Q1 — Deployment + expose [5%]
Namespace `exam-web`. Create a Deployment `store` (image `nginx:1.25`, `3` replicas, container port `80`, pod label `app=store`). Then expose it with a **ClusterIP** Service `store-svc` on port `80` → targetPort `80`.

### Q2 — Rollout strategy + update [6%]
Namespace `exam-web`. Edit the `store` Deployment so its rolling-update strategy is `maxSurge: 2` and `maxUnavailable: 0`. Then update the image to `nginx:1.27` **and record the change-cause** (history must show it).

### Q3 — Multi-container sharing a ConfigMap volume [7%]
Namespace `exam-config`.
- Create a ConfigMap `shared-cfg` with key `message=hello-team`.
- Create a Pod `cfg-share` with two containers, both mounting `shared-cfg` as a volume at `/data`:
  - `reader1`: `busybox:1.36`, `sh -c "cat /data/message && sleep 3600"`
  - `reader2`: `busybox:1.36`, `sh -c "sleep 3600"`

### Q4 — Env from ConfigMap (single key) [5%]
Namespace `exam-config`. Create a Pod `env-single` (image `busybox:1.36`, `sh -c "sleep 3600"`) that sets **one** environment variable `GREETING` whose value comes from the `message` key of ConfigMap `shared-cfg` (use `configMapKeyRef`).

### Q5 — Secret as file via subPath [7%]
Namespace `exam-secure`.
- Create a generic Secret `tls-pw` with key `password=Sup3rP@ss`.
- Create a Pod `sub-pod` (image `nginx:1.25`) that mounts **only** that key as a single file at `/etc/secret/password` using **`subPath`** (the rest of `/etc` must stay intact), read-only.

### Q6 — securityContext (read-only rootfs) [6%]
Namespace `exam-secure`. Create a Pod `hardened` (image `nginx:1.25`) that:
- runs as non-root, user ID `1001`
- has a **read-only root filesystem**
- mounts an `emptyDir` at `/tmp` (writable) so nginx can still start.

### Q7 — ResourceQuota [6%]
Namespace `exam-quota` (create it). Create a ResourceQuota `team-quota` that limits the namespace to:
- `pods: 5`
- `requests.cpu: 1`, `requests.memory: 1Gi`
- `limits.cpu: 2`, `limits.memory: 2Gi`.

### Q8 — Probes (tcpSocket + httpGet) [6%]
Namespace `exam-health`. Create a Deployment `probed2` (image `nginx:1.25`, 2 replicas) with:
- a **readiness** probe: `tcpSocket` on port `80`, initialDelay `5s`, period `10s`
- a **liveness** probe: `httpGet` path `/` port `80`, initialDelay `15s`, period `20s`.

### Q9 — Debug a Pending pod [7%]
Namespace `exam-health`. A Deployment `stuck` exists (created by setup); its pod is **Pending** and never schedules. Diagnose and fix it in place so it runs. Do **not** delete the Deployment. Record the cause + fix in `commands.md`.

### Q10 — Suspended CronJob [5%]
Namespace `exam-batch`. Create a CronJob `nightly`:
- schedule `0 0 * * *`
- image `busybox:1.36`, command `sh -c "echo nightly run"`
- `restartPolicy: OnFailure`
- **suspended** (`suspend: true`).

### Q11 — Job with deadline + TTL [6%]
Namespace `exam-batch`. Create a Job `timed`:
- image `busybox:1.36`, command `sh -c "echo working; sleep 10"`
- `activeDeadlineSeconds: 30`
- `ttlSecondsAfterFinished: 60`
- `backoffLimit: 2`.

### Q12 — Scheduling with nodeSelector [6%]
Namespace `exam-sched`. First label a node: `disktype=ssd` (record the command). Then create a Pod `pinned` (image `nginx:1.25`) that only schedules onto nodes with `disktype=ssd` via `nodeSelector`, and ensure it is `Running`.

### Q13 — ExternalName Service [5%]
Namespace `exam-net`. Create a Service `ext-db` of type **ExternalName** that maps to `db.example.internal` (no selector, no ports needed).

### Q14 — Ingress with TLS [8%]
Namespace `exam-net`. Setup created a Deployment `shop` and Service `shop` (port `80`), plus a TLS Secret `shop-tls`. Create an Ingress `shop-ingress`:
- host `shop.example.com`, path `/` (Prefix) → service `shop` port `80`
- `ingressClassName: nginx`
- TLS: terminate `shop.example.com` using secret `shop-tls`.

### Q15 — NetworkPolicy with namespaceSelector [8%]
Namespace `exam-net`. Setup created pods `web` (label `app=web`, Service `web`) here, and a namespace `exam-clients` (label `team=clients`) with a pod `caller` (label `app=caller`). Create a NetworkPolicy `web-allow` so that `web` pods accept **ingress** on port `80` **only** from pods in namespaces labeled `team=clients`. Deny all other ingress.

### Q16 — Observability (previous logs) [7%]
Namespace `exam-health`. Using the `probed2` Deployment (Q8):
- write the name of one `probed2` pod into `answers/q16.txt` (line 1)
- on line 2, write the command to view the **previous** container's logs (the `--previous` form)
- on line 3, write the command to show that pod's **CPU/memory usage**.

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
| Easy wins (Q1, Q4, Q7, Q10, Q13) | 30 |
| Medium (Q3, Q5, Q6, Q8, Q11, Q12) | 50 |
| Hard / debug (Q2, Q9, Q14, Q15, Q16) | 30 |
| Review flagged | 5 |
