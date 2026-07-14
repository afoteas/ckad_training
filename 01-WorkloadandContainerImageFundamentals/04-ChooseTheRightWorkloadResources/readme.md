# Choose the Right Workload Resources

This lesson explains how to select the correct Kubernetes workload resource based on execution model, fault tolerance needs, and lifecycle behavior.

## Workload Resource Selection

### Pod

Use directly only for short-lived debugging or one-off tasks.

Pods by themselves have no controller-based self-healing or scaling.

### Deployment

Use for long-running stateless services that need scaling, rolling updates, and rollback support.

Typical examples:

- web frontends
- REST APIs
- stateless microservices

### Job

Use for finite tasks that must complete successfully.

Typical examples:

- migration script
- batch processing
- data export/import

### CronJob

Use when Jobs must run on a schedule.

Typical examples:

- daily backup
- hourly report
- periodic maintenance

### DaemonSet

Use for one Pod per node behavior.

Typical examples:

- node log agents
- node metrics exporters
- node-level networking components

## Controller Behavior Highlights

- Deployments maintain desired replica count and support rolling updates.
- Jobs focus on successful completion, not continuous uptime.
- CronJobs create Jobs based on cron schedule rules.
- DaemonSets automatically place one Pod on each eligible node.

## Resource Decision Table

1. Need continuously available stateless service: Deployment.
2. Need finite task completion: Job.
3. Need scheduled recurring execution: CronJob.
4. Need one agent per node: DaemonSet.
5. Need quick ad-hoc debug run: standalone Pod.

## Practical Decision Rules

1. Need continuous stateless service: Deployment.
2. Need task completion once: Job.
3. Need recurring task: CronJob.
4. Need one per node: DaemonSet.
5. Need persistent durable state: pair workload with PVC (covered in lesson 09).

## Summary

Choosing the correct workload type is foundational for reliability and operational efficiency in Kubernetes. Workload controllers encode intent, and Kubernetes reconciles toward that desired state.
