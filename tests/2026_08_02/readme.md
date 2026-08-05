# CKAD Simulation Exam — 2026-08-02

Exam #7 — **gap-fill round**. Tasks target concepts under-represented in Exams #1–#6 (DaemonSet, StatefulSet, affinity, taints, HPA, Helm upgrade/rollback, projected volumes, PDB, egress policy, etc.). Deliberately **omits** heavily drilled patterns (sidecar log tailing, basic ConfigMap key refs, canary splits, Kustomize overlays, simple Ingress TLS, standalone headless Services).

Wording is indirect — infer the Kubernetes objects yourself.

## Format

- **17 tasks, 120 minutes.** Official CKAD domain weights.
- Allowed docs (one browser tab): `kubernetes.io/docs`, `helm.sh/docs`, `kubectl.docs.kubernetes.io`.
- **Every task names a namespace.** Before each task:

  ```
  kubectl config use-context kind-ckad
  ```

- **Graded on the live cluster.** Verify with `kubectl get` / `describe`.
- Save manifests under `answers/`; record imperative work in `answers/commands.md` or the file named in the task.

## Setup

```bash
cd /home/foteas/code/ckad_training/tests/2026_08_02
bash setup.sh
bash setup.sh --reset   # tear down
```

Setup installs **metrics-server** if missing (required for Q17). It also taints one node for Q16.

## When finished

Say **"score my exam"** for a per-task breakdown (pass = 66%).

---

# Tasks

## Application Design & Build (20%)

### Q1 [4%]
**Context.** A node-level agent must run on every Linux node that carries the platform label `workload=edge`. Those nodes are reserved with a `NoSchedule` taint (`dedicated=exam`) so only workloads that explicitly opt in may land there.
**Task.** In namespace `agents`, create a DaemonSet named `edge-agent` using image `busybox:1.36` with command `sh -c "sleep infinity"`. It must schedule only onto nodes labeled `workload=edge` **and** tolerate taint `dedicated=exam:NoSchedule`. Setup has labeled and tainted node `ckad-worker3`.

### Q2 [6%]
**Context.** A replicated cache tier needs stable per-pod DNS names and ordered identity. Clients resolve individual peers through a dedicated discovery Service.
**Task.** In namespace `agents`, create a StatefulSet named `cache` with **3** replicas, image `nginx:1.25`, container port **6379**, and `serviceName: cache-peers`. Create a headless Service `cache-peers` (port **6379**) selecting `app=cache`. Pod template labels must include `app=cache`.

### Q3 [5%]
**Context.** An application must know its own identity at runtime without hard-coding.
**Task.** In namespace `agents`, create a long-running Pod `self-aware` (`busybox:1.36`) that sets environment variable `POD_NAME` to the Pod's own `metadata.name` using the downward API (`fieldRef`). The container command may be `sleep 3600`.

### Q4 [5%]
**Context.** Two replicas of the same web tier must prefer landing on different nodes when capacity allows, but may share a node if no alternative exists.
**Task.** In namespace `agents`, create Deployment `web` (image `nginx:1.25`, **2** replicas, label `app=web`) whose pod template uses **preferred** pod anti-affinity against pods labeled `app=web` on the `kubernetes.io/hostname` topology (weight **100**).

## Application Deployment (20%)

### Q5 [7%]
**Context.** The portal Helm release was installed during cluster bootstrap; operations must scale it out and bump the image without reinstalling.
**Task.** In namespace `release`, upgrade the existing Helm release `portal` so the workload runs **4** replicas and uses image **`nginx:1.27`**. Record commands in `answers/commands.md`.
*(Chart is `localchart/`; values key for image is `image`, replicas `replicaCount`.)*

### Q6 [7%]
**Context.** The last portal upgrade introduced a bad image tag; traffic must return to the previous known-good chart revision.
**Task.** In namespace `release`, roll back Helm release `portal` to its **previous** revision so pods run a working image again. Record commands in `answers/commands.md`.

### Q7 [6%]
**Context.** A blue/green cutover moves all traffic at once — no partial split. The old colour must stop receiving traffic entirely while the new colour serves everyone.
**Task.** In namespace `release`, Deployments `shop-blue` and Service `shop` already exist (blue is live at **3** replicas). Create Deployment `shop-green` (`nginx:1.27`, label `app=shop`, `track=green`) and perform a blue/green cutover so **only** green pods are selected by Service `shop`. End state: green **3** replicas Running, blue **0** replicas. Do **not** modify Service `shop`.

## App Environment, Config & Security (25%)

### Q8 [5%]
**Context.** Configuration and credentials are delivered through a single projected mount rather than separate volumes.
**Task.** In namespace `platform`, create ConfigMap `app-conf` (`mode=production`) and Secret `app-key` (`token=secret123`). Create Pod `projected-vol` (`busybox:1.36`, long-running) mounting a **projected** volume at `/etc/projected` that exposes `mode` from the ConfigMap and `token` from the Secret (each as a file keyed by its name).

### Q9 [5%]
**Context.** Only one key from a credential bundle should appear as a single file without masking other paths under the mount parent.
**Task.** In namespace `platform`, create Secret `db-pass` with `password=dbsecret`. Create Pod `subpath-mount` (`nginx:1.25`) mounting **only** the `password` key as file `/etc/db/password` using **`subPath`**, read-only.

### Q10 [7%]
**Context.** Maintenance windows require at least one instance of the API to remain schedulable during voluntary disruptions.
**Task.** In namespace `platform`, Deployment `api` already exists (**3** replicas). Create PodDisruptionBudget `api-pdb` ensuring **at least 2** pods labeled `app=api` are available at all times.

### Q11 [4%]
**Context.** Hardening requires non-root execution, the runtime default seccomp profile, and all capabilities dropped.
**Task.** In namespace `platform`, create long-running Pod `locked` (`busybox:1.36`) with `runAsNonRoot: true`, `runAsUser: 1000`, `seccompProfile.type: RuntimeDefault`, and capabilities drop `ALL`. Mount writable `emptyDir` at `/tmp` (read-only root filesystem). Pod must be **Running**.

### Q12 [4%]
**Context.** A team namespace caps aggregate consumption before workloads are admitted.
**Task.** In namespace `policy`, create ResourceQuota `team-cap` limiting the namespace to **10** pods and **2** total CPU requests (`requests.cpu`). Then create a long-running Pod `quota-ok` (`busybox:1.36`) with requests `cpu: 100m`, `memory: 64Mi` that becomes **Running**.

## Services & Networking (20%)

### Q13 [4%]
**Context.** In-cluster clients should resolve an external database hostname through Kubernetes DNS without deploying pods behind it.
**Task.** In namespace `edge`, create Service `external-db` of type **ExternalName** mapping to `postgres.vendor.example.com`.

### Q14 [7%]
**Context.** Frontend pods may call the backend only on its application port; all other outbound traffic from frontends must be blocked except DNS resolution.
**Task.** In namespace `edge`, pods `frontend` and `backend` already exist (`app=frontend` / `app=backend`). Create NetworkPolicy `front-egress` applying to frontends that allows egress to backend pods on TCP **8080** and allows egress for **DNS (UDP 53)** only. Deny all other egress from frontends.

### Q15 [9%]
**Context.** Zero-trust ingress: nothing receives traffic by default; only monitoring stations in a trusted namespace may scrape exporters on TCP 9100.
**Task.** In namespace `edge`, first deny **all ingress** to every pod (policy `edge-deny-ingress`). Then allow ingress to pods labeled `app=exporter` on TCP **9100** exclusively from namespaces labeled `zone=monitoring` (policy `edge-allow-scrape`). Namespace `edge-monitors` is labeled `zone=monitoring`.

## Observability & Maintenance (15%)

### Q16 [8%]
**Context.** A diagnostic pod never schedules; the cluster events mention taints and the pod targets a reserved node pool.
**Task.** In namespace `triage`, Pod `blocked` exists and stays **Pending**. It is meant to run on edge nodes but lacks permission for the node taint. Fix it so it runs — **without** removing the node taint. Record cause and fix in `answers/commands.md`.

### Q17 [7%]
**Context.** Traffic growth requires horizontal autoscaling based on CPU once metrics are available.
**Task.** In namespace `triage`, Deployment `autoscaled` already exists. Create HorizontalPodAutoscaler `autoscaled-hpa` targeting that Deployment with **min 2**, **max 8** replicas, targeting **50%** average CPU utilization.

---

## Answer file map

| Task | Where |
|------|-------|
| Q1–Q4, Q8–Q15 (manifests) | `answers/qNN.yaml` |
| Q5, Q6, Q7, Q16 (imperative) | `answers/commands.md` |
| Q17 | `answers/q17.yaml` |

## Topics intentionally omitted (covered in Exams #1–#6)

Sidecar log shipping · basic ConfigMap `configMapKeyRef` · canary replica math · Kustomize overlays · simple Ingress TLS · standalone headless Service (without StatefulSet) · basic ClusterRole pod-reader only
