# Advanced Scheduling and Scalability Patterns

This module focuses on advanced scheduling and cluster-level scaling:

- PriorityClasses and preemption for critical workload protection
- topology spread constraints for high availability across failure domains
- horizontal vs vertical autoscaling and when to use each
- Cluster Autoscaler for node-level elasticity
- descheduler for post-deployment workload rebalancing

## CKAD Exam Relevance

**Priority: Medium — study selectively.** Lessons 01–04 on **PriorityClasses** and **topology spread constraints** are the most exam-relevant. You should be able to write a `PriorityClass` manifest, reference `priorityClassName` on a Pod, and define `topologySpreadConstraints` with `maxSkew`, `topologyKey`, `whenUnsatisfiable`, and `labelSelector`. Lessons 05–06 recap HPA vs VPA (covered in depth in module 12). **Cluster Autoscaler** (lesson 07) and **descheduler** (lessons 08–09) are production operations topics — know the concepts but do not prioritize hands-on practice for CKAD.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | PriorityClasses and Preemption Explained | Medium | Know priority values, preemption policy, and when critical Pods evict lower-priority ones |
| 02 | Creating PriorityClasses and Observing Preemption | Medium | Write `PriorityClass` YAML and set `priorityClassName` on Pods |
| 03 | Topology Spread Constraints | **High** | Understand `maxSkew`, `topologyKey`, `whenUnsatisfiable`, and `labelSelector` |
| 04 | Zone-Aware Distribution with Spread Constraints | **High** | Hands-on spread across zones using `topology.kubernetes.io/zone` |
| 05 | Horizontal vs. Vertical Pod Autoscalers | Medium | HPA scales replicas; VPA scales per-Pod resources — avoid running both on same metrics |
| 06 | Installing and Testing the Vertical Pod Autoscaler | Low | VPA is not core Kubernetes; know update modes (`Off`, `Initial`, `Recreate`, `Auto`) conceptually |
| 07 | Cluster Autoscaler Concepts | Low | Know it adds/removes nodes when Pods are unschedulable — not a hands-on CKAD task |
| 08 | Descheduler for Post-Deployment Rebalancing | Low | Corrective rebalancing after initial scheduling — conceptual only |
| 09 | Running Descheduler as a CronJob | Low | Descheduler strategies and CronJob deployment are beyond CKAD scope |

## Lessons

1. `01-PriorityClassesAndPreemptionExplained`
2. `02-CreatingPriorityClassesAndObservingPreemption`
3. `03-TopologySpreadConstraints`
4. `04-ZoneAwareDistributionWithSpreadConstraints`
5. `05-HorizontalVsVerticalPodAutoscalers`
6. `06-InstallingAndTestingTheVerticalPodAutoscaler`
7. `07-ClusterAutoscalerConcepts`
8. `08-DeschedulerForPostDeploymentRebalancing`
9. `09-RunningDeschedulerAsACronJob`

## Learning Objectives

- Explain why PriorityClasses exist and how preemption frees resources for critical Pods.
- Create PriorityClasses and observe low-priority Pod eviction under resource pressure.
- Define topology spread constraints to distribute replicas across failure domains.
- Deploy workloads with zone-aware spread constraints for high availability.
- Compare HPA and VPA and identify when each autoscaling approach fits.
- Install VPA and observe automatic resource right-sizing in action.
- Describe how Cluster Autoscaler scales nodes based on unschedulable Pods.
- Explain descheduler strategies for rebalancing imbalanced clusters.
- Deploy the descheduler via Helm and run low-node-utilization rebalancing on a schedule.
