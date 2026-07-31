# CKAD Practice Exam — 2026-07-30

Exam #4 — built to mirror the **real CKAD** as closely as possible: 18 tasks, weighted by the official domain split, **2 hours**, graded on the **live cluster**. New this round: **Helm** and **Kustomize** (Application Deployment domain), plus RBAC, PVC storage, canary/rollback, and two debug tasks.

## Domain weighting (matches the real exam)

| Domain | Weight | Tasks |
|--------|-------:|-------|
| Application Design & Build | 20% | Q1–Q4 |
| Application Deployment | 20% | Q5–Q7 |
| App Environment, Config & Security | 25% | Q8–Q12 |
| Services & Networking | 20% | Q13–Q15 |
| Observability & Maintenance | 15% | Q16–Q18 |

## Rules (exam-realistic)

- **120 minutes.** Set a timer and don't stop it.
- Allowed: one `kubernetes.io/docs`, `helm.sh/docs`, and one `kubectl.docs.kubernetes.io` (Kustomize) tab. Nothing else.
- Each task names its **namespace** and (like the real exam) reminds you which "cluster/context" — here always `kind-ckad`. Switch context at the top of each task in real life: `kubectl config use-context kind-ckad`.
- Some tasks reference **files/objects the setup created for you** (a broken Deployment, a Kustomize base, a local Helm chart). Read the task for paths.
- **Grade = live cluster state.** A perfect YAML that isn't applied scores 0. Verify with `kubectl get`/`describe` before moving on. Pods are immutable — edit via `kubectl replace --force` or delete + apply.
- Record imperative work (Helm, Kustomize, rollout, top, logs) in `answers/commands.md`.
- Partial credit exists. Flag hard ones and return.

## Setup

```bash
cd /home/foteas/code/ckad_training/tests/2026_07_30
bash setup.sh          # namespaces + seeded objects + kustomize base + local helm chart
bash setup.sh --reset   # tear down
```

Setup also drops two helper assets in this folder:
- `kustomize/base/` — a working Kustomize base for **Q6**.
- `localchart/` — a minimal Helm chart for **Q5** (offline fallback if the bitnami repo is unreachable).

## When finished

Say **"score my exam"** — I read `answers/`, inspect the live cluster, and return a per-task + per-domain breakdown with pass/fail (pass = 66%).

---

# Tasks

## Application Design & Build (20%)

### Q1 — Sidecar sharing an emptyDir [6%]
Namespace `build`. Create a Pod `weblog` with two containers sharing an `emptyDir` volume mounted at `/var/log/app`:
- `writer`: `busybox:1.36`, command `sh -c "while true; do date >> /var/log/app/access.log; sleep 2; done"`
- `sidecar`: `busybox:1.36`, command `sh -c "tail -F /var/log/app/access.log"`

The Pod must reach `Running` with **both** containers ready (`2/2`).

### Q2 — Parallel Job [5%]
Namespace `build`. Create a Job `bulk` that runs image `busybox:1.36`, command `sh -c "echo processing; sleep 5"`, with **`completions: 6`** and **`parallelism: 2`**, `restartPolicy: Never`. It must finish successfully (6/6 completions).

### Q3 — CronJob with history limits [4%]
Namespace `build`. Create a CronJob `report`:
- schedule `*/5 * * * *`
- image `busybox:1.36`, command `sh -c "echo report"`
- `restartPolicy: OnFailure`
- keep only `successfulJobsHistoryLimit: 2` and `failedJobsHistoryLimit: 1`.

### Q4 — Init container gate [5%]
Namespace `build`. Create a Pod `gated` whose **init container** blocks until a Service named `payments` resolves, then the main container runs:
- init `wait`: `busybox:1.36`, command `sh -c "until nslookup payments.build.svc.cluster.local; do echo waiting; sleep 2; done"`
- main `app`: `nginx:1.25`.

Then create a ClusterIP Service `payments` (port `80`) in `build` selecting `app=store` (it need not have endpoints — DNS resolution is enough) so the init container passes and the Pod reaches `Running`.

## Application Deployment (20%)

### Q5 — Install a Helm release [7%]
Namespace `deploy`. Install the `nginx` chart from the **bitnami** chart repository (`https://charts.bitnami.com/bitnami`) as a release named **`shopfront`** in namespace `deploy`. The release must run **2 replicas**.

### Q6 — Kustomize overlay [7%]
Namespace `deploy`. A Kustomize base exists at `kustomize/base` (Deployment `kbase`, 1 replica, image `nginx:1.24`). Create an overlay under `answers/kustomize/overlay` that sets the replica count to **4** and the image to **`nginx:1.27`**, and apply it to namespace `deploy`.

### Q7 — Rolling update + rollback [6%]
Namespace `deploy`. A Deployment `web-app` (image `nginx:1.24`, 3 replicas) exists. Update its image to `nginx:1.26` (recording a change-cause), then roll it back to the previous revision. The final running image must be `nginx:1.24`.

## App Environment, Config & Security (25%)

### Q8 — ConfigMap as env + volume [5%]
Namespace `config`. Create a ConfigMap `app-cfg` with `LOG_LEVEL=debug` and `MODE=prod`. Create a Pod `cfg-consumer` (`busybox:1.36`, `sh -c "sleep 3600"`) that:
- injects **all** keys as env vars via `envFrom`
- **and** mounts the ConfigMap as a volume at `/etc/appcfg`.

### Q9 — Secret as volume [4%]
Namespace `config`. Create a generic Secret `db-cred` with `user=admin` and `pass=s3cr3t`. Create a Pod `sec-consumer` (`nginx:1.25`) that mounts it **read-only** at `/etc/db` (each key as a file).

### Q10 — RBAC [7%]
Namespace `rbac`. Create:
- a ServiceAccount `deployer`
- a Role `pod-manager` allowing `get,list,watch,create,delete` on `pods` (core API group)
- a RoleBinding `deployer-binding` binding the Role to the ServiceAccount.
Verify: `kubectl -n rbac auth can-i create pods --as=system:serviceaccount:rbac:deployer` should return `yes`.

### Q11 — securityContext [5%]
Namespace `secure`. Create a Pod `locked` (`busybox:1.36`, `sh -c "sleep 3600"`) that:
- runs as user `1000`, group `2000`, and sets `fsGroup: 3000`
- drops **all** Linux capabilities.
It must reach `Running`.

### Q12 — PVC + mount [4%]
Namespace `storage`. Create:
- a PersistentVolumeClaim `data-pvc`, `ReadWriteOnce`, request `100Mi` (use the default StorageClass).
- a Pod `data-pod` (`nginx:1.25`) mounting it at `/usr/share/nginx/html`.
Pod must be `Running` and PVC `Bound`.

## Services & Networking (20%)

### Q13 — Service for a Deployment [4%]
Namespace `net`. Setup created Deployment `api` (label `app=api`, port `80`). Expose it with a ClusterIP Service `api-svc` on port `80` → targetPort `80`.

### Q14 — Ingress path routing [7%]
Namespace `net`. Setup created Deployments+Services `shop` and `blog` (both port `80`). Create one Ingress `site` (class `nginx`, host `site.example.com`) routing:
- path `/shop` (Prefix) → service `shop:80`
- path `/blog` (Prefix) → service `blog:80`.

### Q15 — NetworkPolicy [9%]
Namespace `net`. `api` pods (label `app=api`) must accept **ingress on port `80` only** from:
- pods labeled `role=frontend` **in the same namespace**, AND
- any pod in the namespace `net-clients` (label `access=allowed`).
All other ingress denied. Create NetworkPolicy `api-allow`. (Setup created namespace `net-clients` and a `caller` pod there.)

## Observability & Maintenance (15%)

### Q16 — Debug a never-Ready Deployment [6%]
Namespace `observe`. Setup created Deployment `flaky` whose pods run but **never become Ready**. Diagnose and fix it in place so all replicas are Ready. Do not delete the Deployment. Record cause + fix in `commands.md`.

### Q17 — Top pods [4%]
Namespace `observe`. Write into `answers/q17.txt`:
- line 1: the command that lists pod CPU/memory usage in `observe`
- line 2: the **name of the pod consuming the most CPU** in `observe`.

### Q18 — Crashing pod logs [5%]
Namespace `observe`. Setup created a pod `crasher` in `CrashLoopBackOff`. In `answers/q18.txt`:
- line 1: the command to view the **previous** container's logs
- line 2: the last log line the crashing container printed before it died
- line 3: the command to view the pod's events.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q4, Q8–Q15 | `answers/qNN.yaml` |
| Q5, Q7 (imperative) | `answers/commands.md` |
| Q6 overlay | `answers/kustomize/overlay/` + command in `commands.md` |
| Q16 fix | `commands.md` (+ any edited manifest) |
| Q17, Q18 | `answers/q17.txt`, `answers/q18.txt` |

## Time budget

| Phase | Min |
|-------|----:|
| Read + flag all | 5 |
| Design & Build (Q1–4) | 20 |
| Deployment (Q5–7) | 25 |
| Config/Security (Q8–12) | 30 |
| Networking (Q13–15) | 25 |
| Observability (Q16–18) | 10 |
| Review flagged | 5 |
