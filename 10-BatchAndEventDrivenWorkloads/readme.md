# Batch and Event-Driven Workloads

This module covers Kubernetes workloads designed to run one or more tasks to completion, from simple batch jobs with retry logic to scheduled recurring tasks and event-driven autoscaling.

## CKAD Exam Relevance

**Priority: Medium–High.** **Jobs** and **CronJobs** are regular CKAD topics — know `completions`, `parallelism`, `backoffLimit`, cron schedule syntax, `concurrencyPolicy`, and `suspend`. Lessons 01–07 are the exam focus. **KEDA** (lessons 08–09) and **JobSet** (lesson 10) are advanced production patterns and are unlikely to appear on CKAD. If you already understand Deployments, this module fills an important gap because the exam often asks you to create a Job or CronJob manifest from scratch.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Job Basics and Retry Strategy | **High** | Job fundamentals, `backoffLimit`, and completion behavior are core topics |
| 02 | Creating a Single-Run Job with Retries | **High** | Writing a Job manifest with retry logic is a common exam task |
| 03 | Parallel and Indexed Jobs | **High** | `parallelism`, `completions`, and parallel execution patterns are tested |
| 04 | Implementing an Indexed Parallel Job | Medium | IndexedJob is useful; appears less often than basic Jobs |
| 05 | CronJob Features and Concurrency Policy | **High** | Cron schedule syntax and `concurrencyPolicy` are regularly tested |
| 06 | Managing CronJob Suspension and History Limits | Medium | `suspend` and `successfulJobsHistoryLimit` are good to know |
| 07 | Cleaning Up with TTLSecondsAfterFinished | Medium | `ttlSecondsAfterFinished` is useful; occasionally tested |
| 08 | Event-Driven Autoscaling with KEDA | Low | KEDA is not a CKAD topic |
| 09 | Triggering Jobs from Queue Depth via KEDA | Low | KEDA ScaledJob is production-focused, not exam-focused |
| 10 | JobSet for Coordinated Multi-Job Workloads | Low | JobSet is too new/advanced for CKAD |

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
