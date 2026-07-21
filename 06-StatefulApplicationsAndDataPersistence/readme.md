# Stateful Applications and Data Persistence

This module covers Kubernetes patterns for stateful workloads such as databases, queues, and scheduled backup pipelines.

## CKAD Exam Relevance

**Priority: High.** CKAD tests **StatefulSets** (stable network IDs, `volumeClaimTemplates`), **PVC/PV** creation and mounting, **Jobs**, and **CronJobs** (schedule syntax, `concurrencyPolicy`, `suspend`). You should know when to use a StatefulSet vs a Deployment and how to write a basic CronJob manifest. PVC online resize (lessons 03–04) and Pod Disruption Budgets (lesson 07) appear less often but are worth skimming. Database-specific probes (lesson 08) reinforce probe skills from module 05.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | StatefulSet Fundamentals and Ordinals | **High** | Stable network IDs, ordered deployment, and headless Services are tested |
| 02 | Deploying a MySQL StatefulSet with VolumeClaimTemplates | **High** | `volumeClaimTemplates` and per-Pod PVC provisioning are common tasks |
| 03 | Resizing Persistent Volumes and File Systems | Low | PVC expansion is a newer feature; rarely tested hands-on |
| 04 | Expanding a PVC for a Stateful Workload | Low | Filesystem resize steps are production ops, not core CKAD |
| 05 | Jobs and CronJobs for Batch Processing | **High** | Job vs CronJob, `completions`, `parallelism`, and `backoffLimit` are exam topics |
| 06 | Automating Nightly Backups with CronJob | **High** | CronJob schedule syntax and practical manifest writing are tested |
| 07 | Pod Disruption Budgets (PDB) for Stateful Apps | Medium | Know `minAvailable` / `maxUnavailable`; occasionally appears on CKAD |
| 08 | Readiness and Startup Probes for Databases | Medium | Reinforces probe skills; database warm-up probes are useful context |

## Lesson Order

1. `01-StatefulSetFundamentalsAndOrdinals`
2. `02-DeployingAMySQLStatefulSetWithVolumeClaimTemplates`
3. `03-ResizingPersistentVolumesAndFileSystems`
4. `04-ExpandingAPVCForAStatefulWorkload`
5. `05-JobsAndCronJobsForBatchProcessing`
6. `06-AutomatingNightlyBackupsWithCronJob`
7. `07-PodDisruptionBudgetsPDBForStatefulApps`
8. `08-ReadinessAndStartupProbesForDatabases`

## What You Learn

- when to use StatefulSets instead of Deployments
- how ordinals (`-0`, `-1`, `-2`) provide stable identity and ordered lifecycle
- how `volumeClaimTemplates` auto-provision one PVC/PV per StatefulSet pod
- how to safely expand PVC capacity and verify filesystem growth
- when to use Jobs vs CronJobs for one-off and scheduled batch work
- how to protect stateful workloads during maintenance with Pod Disruption Budgets
- how readiness/startup probes prevent early database traffic and restart loops

## Objectives 
- describe StatefulSet guarantees: stable network IDs, storage, and ordered updates
- create a StatefulSet that provisions persistent disks automatically
- list the conditions and steps for online PVC resize and filesystem expansion
- perform storage resize and verify filesystem growth in the container
- differentiate between Job and CronJob patterns and best practices
- schedule a CronJob to dump and upload database backups
- state how to protect availability during voluntary disruptions with PDBs
- describe how to configure probes to detect warm‑up and readiness in stateful services