# Exam Format and Strategy

The CKAD is a **hands-on, timed, proctored** exam. You solve real cluster tasks from your browser — no multiple choice.

## Format at a Glance

| Item | Detail |
|------|--------|
| Duration | **2 hours** |
| Tasks | ~15–20 (varies by exam version) |
| Passing score | ~67% (check current PSI/Linux Foundation page) |
| Environment | Remote desktop + terminal + one Kubernetes cluster |
| Docs | **kubernetes.io/docs allowed** (one browser tab) |
| Copy/paste | Limited — practice typing YAML |

## Time Budget

| Phase | Time | Action |
|-------|------|--------|
| First 5 min | Scan all tasks | Flag easy vs hard; note namespace per task |
| Per task | ~6–8 min avg | Read → implement → **verify** → next |
| Last 10 min | Review | Re-check flagged tasks, fix quick wins |
| Stuck >5 min | Skip | Return later; partial credit beats a blank |

## Task Patterns (What to Expect)

- Create or fix a **Deployment** (probes, resources, env, volumes)
- Expose with **Service** or **Ingress**
- Create **ConfigMap/Secret** and mount/inject
- Write **Job** or **CronJob**
- **NetworkPolicy** allow/deny rules
- **RBAC**: ServiceAccount + Role + RoleBinding
- **Taint/toleration** or **nodeSelector/affinity**
- **HPA**, **PDB**, **StatefulSet** (less frequent but possible)
- **Debug**: fix CrashLoopBackOff, ImagePullBackOff, wrong selector

## Strategy Tips

1. **Read the namespace first** — every object goes in the namespace stated in the task.
2. **Use imperative generators** for speed, then edit (see [lesson 02](02-ImperativeKubectlAndManifestGeneration/readme.md)).
3. **Verify before moving on** — see [lesson 04](04-PostTaskVerificationChecklist/readme.md).
4. **Do not over-engineer** — meet the spec exactly; extra labels or annotations are wasted time.
5. **kubectl explain** works in the exam terminal — use it when unsure of a field path.

## What Is NOT on CKAD

- Cluster installation, etcd backup, control-plane upgrades (CKA)
- Deep policy engines (Gatekeeper/Kyverno) — CKS
- Writing Go operators or client-go code
- Service mesh configuration

## Suggested Prep Timeline

| Week | Focus |
|------|-------|
| 1–2 | Modules 01, 11, 16 + lesson 02 (imperative kubectl) |
| 3 | Modules 05, 08, 12 |
| 4 | Modules 02, 06 + lesson 05 (timed scenarios) |
| 5 | Full timed runs + weak-area review |

## Key Takeaway

The exam rewards **speed + correctness**, not perfection. Scan tasks, budget time, generate YAML fast, verify every answer, and skip stuck tasks early.
