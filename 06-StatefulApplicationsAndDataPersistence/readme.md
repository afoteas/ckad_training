# Stateful Applications and Data Persistence

This module covers Kubernetes patterns for stateful workloads such as databases, queues, and scheduled backup pipelines.

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