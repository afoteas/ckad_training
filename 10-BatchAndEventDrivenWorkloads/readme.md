# Batch and Event-Driven Workloads

This module covers Kubernetes workloads designed to run one or more tasks to completion, from simple batch jobs with retry logic to scheduled recurring tasks and event-driven autoscaling.

## Lesson Order

1. `01-JobBasicsAndRetryStrategy`
2. `02-CreatingASingleRunJobWithRetries`
3. `03-ParallelAndIndexedJobs`
4. `04-ImplementingAnIndexedParallelJob`
5. `05-CronJobFeaturesAndConcurrencyPolicy`
6. `06-ManagingCronJobSuspensionAndHistoryLimits`
7. `07-CleaningUpWithTTLSecondsAfterFinished`
8. `08-EventDrivenAutoscalingWithKEDA`
9. `09-TriggeringJobsFromQueueDepthViaKEDA`
10. `10-JobSetForCoordinatedMultiJobWorkloads`

## What You Learn

- how Jobs differ from Deployments and when to use each
- how to configure retry logic using backoffLimit and exponential backoff
- how to run parallel and indexed workloads for large static datasets
- how to schedule recurring tasks with CronJobs using cron syntax
- how to manage CronJob concurrency policies and history limits
- how to automatically clean up finished Jobs using TTLSecondsAfterFinished
- how KEDA enables event-driven autoscaling based on external metrics
- how to combine Jobs and KEDA for queue-driven batch processing
- how JobSet coordinates multiple Jobs as a single unit for distributed workloads

## Objectives

- create and monitor a Job with retry logic
- configure parallel execution with a fixed completion count
- use IndexedJob to distribute partitioned workloads across pods
- define a CronJob with cron scheduling syntax and concurrency controls
- suspend and resume a CronJob during maintenance windows
- enable automatic cleanup of completed Job objects
- install and configure KEDA for event-driven scaling
- scale Kubernetes deployments based on external queue depth
- orchestrate a leader/worker JobSet with group-level success policy
