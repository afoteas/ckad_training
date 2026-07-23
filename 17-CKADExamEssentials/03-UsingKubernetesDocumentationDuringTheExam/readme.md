# Using Kubernetes Documentation During the Exam

You may use **https://kubernetes.io/docs/** during CKAD (one browser tab). Knowing **where to look** saves more time than memorizing every field.

## Allowed vs Not Allowed

| Allowed | Not allowed |
|---------|-------------|
| kubernetes.io/docs | Stack Overflow, blogs, ChatGPT |
| kubernetes.io/blog (sometimes) | GitHub (except as linked from docs) |
| Copy small snippets from docs | Someone else's exam answers |

Confirm current rules on the Linux Foundation / PSI candidate handbook before your exam date.

## Fast Search Tactics

1. **Use the docs search bar** — search exact resource names: `PersistentVolumeClaim`, `NetworkPolicy`, `Ingress`.
2. **Concept pages** — e.g. "Configure a Pod to Use a ConfigMap" — have full YAML examples.
3. **API reference** — `https://kubernetes.io/docs/reference/kubernetes-api/` for exact field names.
4. **Tasks section** — step-by-step guides for common operations.

## Bookmarks Worth Preparing (mental map)

| Topic | Docs path (search term) |
|-------|-------------------------|
| Probes | "Configure Liveness Readiness Startup Probes" |
| ConfigMap / Secret | "Configure Pod ConfigMap" / "Distribute Credentials Securely" |
| PVC | "Configure a Pod to Use a PersistentVolume" |
| Ingress | "Ingress" concept + "Create an External Load Balancer" |
| NetworkPolicy | "Network Policies" concept |
| RBAC | "Configure Service Accounts" / "Role Binding" |
| Taints | "Taints and Tolerations" |
| Jobs / CronJobs | "Running Automated Tasks with a CronJob" |

## kubectl explain vs Docs

| Tool | Best for |
|------|----------|
| `kubectl explain` | Field path and type while in terminal |
| kubernetes.io/docs | Full working YAML examples, concepts |

Use both: `explain` for "what field?", docs for "what does a complete manifest look like?".

## Copy-Paste Discipline

- Paste from docs into your YAML file, then **edit names, namespaces, labels** to match the task.
- Remove unrelated fields the task does not ask for (keeps manifests clean and fast to read).
- Watch indentation — YAML breaks silently.

## CKAD Tips

- Practice finding examples **before** exam day — do not learn the docs layout during the test.
- If stuck, search the **task title wording** from the exam (often matches docs task pages).
- API version: prefer `apps/v1`, `networking.k8s.io/v1`, `batch/v1` — check the docs example's `apiVersion`.

## Key Takeaway

The docs are a tool, not a crutch. Pre-learn where probe, volume, Ingress, and RBAC examples live so you can paste and adapt in under 2 minutes.
