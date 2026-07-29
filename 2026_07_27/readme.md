# CKAD Practice Exam — 2026-07-27

A realistic, timed CKAD-style mock exam. **16 tasks, weighted, 2 hours.** Work against your local `kind` cluster (context `kind-ckad`).

## Rules (mirror the real exam)

- Time limit: **120 minutes**. Set a timer.
- One `kubernetes.io/docs` tab allowed. No other help.
- Every task states its **namespace** — create it if it does not exist, and put the object there.
- Write your answers under `answers/` (one file per task, e.g. `answers/q01.yaml`). For imperative/live tasks, record the exact commands in `answers/commands.md`.
- Partial credit exists. Skip and return; do not get stuck.

## Setup

Run this once before starting the clock. It creates the pre-existing objects some "fix it" tasks depend on.

```bash
cd /home/foteas/code/ckad_training/playground/2026_07_27
bash setup.sh
```

To reset between attempts:

```bash
bash setup.sh --reset   # deletes exam namespaces, then recreates
```

## How scoring works

When you are done, tell me **"score my exam"**. I will:
1. Read your `answers/` files and inspect live cluster state.
2. Check each task's required spec.
3. Give a per-task breakdown, total %, and pass/fail (pass = 66%).

---

## Tasks

Weights in **[ ]**. Namespaces are stated per task.

### Q1 — Deployment [4%]
Namespace `ckad-web`. Create a Deployment named `frontend`:
- image `nginx:1.25`
- `4` replicas
- container port `80`
- pod label `app=frontend`

### Q2 — Rolling update + rollback [6%]
Namespace `ckad-web`. On the `frontend` Deployment from Q1:
- update the image to `nginx:1.27` and record the change cause.
- Then **roll back** to the previous revision.
- Leave the Deployment running the rolled-back (`nginx:1.25`) image.

### Q3 — Service [5%]
Namespace `ckad-web`. Expose `frontend` with a Service named `frontend-svc`:
- type `ClusterIP`
- port `80` → targetPort `80`
- must select the `frontend` pods.

### Q4 — NodePort [5%]
Namespace `ckad-web`. Create a Service `frontend-nodeport`:
- type `NodePort`
- port `80`, targetPort `80`, nodePort `30081`
- selects the `frontend` pods.

### Q5 — ConfigMap + env [6%]
Namespace `ckad-config`. 
- Create a ConfigMap `app-settings` with `LOG_LEVEL=debug` and `APP_MODE=prod`.
- Create a Deployment `configured-app` (image `busybox:1.36`, command `sh -c "sleep 3600"`, 1 replica) whose container gets **both** ConfigMap keys as environment variables.

### Q6 — Secret as volume [6%]
Namespace `ckad-config`.
- Create a generic Secret `db-secret` with key `password=S3cr3t!`.
- Create a Pod `secret-reader` (image `busybox:1.36`, command `sh -c "sleep 3600"`) that mounts `db-secret` as a **volume** at `/etc/db` (read-only).

### Q7 — Resources [5%]
Namespace `ckad-config`. Create a Pod `limited` (image `nginx:1.25`) with:
- requests: `cpu=100m`, `memory=64Mi`
- limits: `cpu=250m`, `memory=128Mi`

### Q8 — Probes [7%]
Namespace `ckad-health`. Create a Deployment `probed` (image `nginx:1.25`, 2 replicas) with:
- a **readiness** probe: HTTP GET `/` on port `80`, initialDelay `5s`, period `10s`
- a **liveness** probe: HTTP GET `/` on port `80`, initialDelay `10s`, period `15s`

### Q9 — Fix the broken Deployment [7%]
Namespace `ckad-health`. A Deployment `broken-app` already exists (created by setup) and its pods are **not** becoming Ready. Diagnose and fix it so all replicas are Ready. Do **not** delete the Deployment; fix it in place. (Hint: check image + probe.)

### Q10 — Job [5%]
Namespace `ckad-batch`. Create a Job `pi` that runs image `perl:5.34` with command `perl -Mbignum=bpi -wle "print bpi(200)"`. It must complete successfully (`completions=1`).

### Q11 — CronJob [5%]
Namespace `ckad-batch`. Create a CronJob `heartbeat`:
- schedule: every 5 minutes (`*/5 * * * *`)
- image `busybox:1.36`, command `sh -c "date; echo alive"`
- `restartPolicy: OnFailure`.

### Q12 — Multi-container (sidecar) [7%]
Namespace `ckad-design`. Create a Pod `web-logger` with two containers sharing an `emptyDir` volume named `logs` mounted at `/var/log/app`:
- `writer`: `busybox:1.36`, command `sh -c "while true; do date >> /var/log/app/out.log; sleep 5; done"`
- `reader`: `busybox:1.36`, command `sh -c "tail -f /var/log/app/out.log"`

### Q13 — ServiceAccount + RBAC [7%]
Namespace `ckad-rbac`.
- Create a ServiceAccount `reader-sa`.
- Create a Role `pod-reader` allowing `get,list,watch` on `pods`.
- Bind the Role to `reader-sa` with a RoleBinding `read-pods`.
- Create a Pod `rbac-pod` (image `nginx:1.25`) that uses `reader-sa`.

### Q14 — NetworkPolicy [8%]
Namespace `ckad-netpol`. Setup created `api` (label `app=api`, exposed by Service `api`) and `client` (label `app=client`) pods.
- Create a NetworkPolicy `allow-client` so that the `api` pods only accept **ingress** on port `80` from pods labeled `app=client` in the same namespace. All other ingress to `api` is denied.
- (Enforcement note: your kind cluster uses kindnet and may not enforce — you are graded on the correct policy YAML.)

### Q15 — PVC + mount [7%]
Namespace `ckad-storage`.
- Create a PersistentVolumeClaim `data-pvc`: accessMode `ReadWriteOnce`, request `256Mi`, use the default StorageClass.
- Create a Pod `storage-pod` (image `nginx:1.25`) that mounts `data-pvc` at `/usr/share/nginx/html`.

### Q16 — Observability [5%]
Namespace `ckad-health`. 
- From the running pods of the `probed` Deployment (Q8), find the pod with the **most restarts** and write its **name** into `answers/q16.txt`.
- Also write the command you used on the second line of that file.

---

## Answer file map

| Task | Where to put your answer |
|------|--------------------------|
| Q1–Q15 (manifests) | `answers/qNN.yaml` (the YAML you applied) |
| Any imperative/live commands | `answers/commands.md` (label per task) |
| Q16 | `answers/q16.txt` |

Apply everything to the **live cluster** too — scoring inspects both your files and the cluster.

## Time budget suggestion

| Phase | Minutes |
|-------|---------|
| Read + flag all tasks | 5 |
| Easy wins (Q1, Q3, Q4, Q7, Q10, Q11) | 30 |
| Medium (Q5, Q6, Q8, Q12, Q13, Q15) | 50 |
| Hard / debug (Q2, Q9, Q14, Q16) | 30 |
| Review flagged | 5 |
