# Debugging and Troubleshooting Applications

This module focuses on practical Kubernetes troubleshooting for pod startup failures, crash loops, image pull issues, live debugging, and safe local access to in-cluster services.

## CKAD Exam Relevance

**Priority: High — essential exam skill.** CKAD does not have a separate "debugging" section, but nearly every task requires you to verify your work and fix failures quickly. This module maps directly to exam scenarios: diagnosing **CrashLoopBackOff** and **ImagePullBackOff**, creating **imagePullSecrets**, using **`kubectl port-forward`**, **`kubectl exec`**, and **ephemeral containers** (`kubectl debug`). The workflow `get → describe → logs → events` should become automatic before you sit the exam. All eight lessons are worth practicing.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Pod Lifecycle and Failure States | **High** | Know Pod phases and container states to diagnose problems fast |
| 02 | Diagnosing CrashLoopBackOff with Logs and Events | **High** | CrashLoopBackOff diagnosis via logs and events is a core exam skill |
| 03 | Image Pull Errors and Registry Auth | **High** | Understand why `ImagePullBackOff` happens and how to fix it |
| 04 | Fixing ImagePullBackOff via ImagePullSecret | **High** | Creating and attaching `imagePullSecrets` is a common hands-on task |
| 05 | Ephemeral Containers and Kubectl Debug | **High** | `kubectl debug` with ephemeral containers is tested on modern CKAD |
| 06 | Attaching an Ephemeral Container to Inspect Environment | **High** | Hands-on ephemeral container attachment for live debugging |
| 07 | Port Forwarding and Local Debugging Techniques | **High** | `kubectl port-forward` is essential for testing in-cluster services |
| 08 | Live Debug of Service via Port-Forward and Curl | **High** | Combine port-forward + curl to validate Service connectivity |

## Lesson Order

1. `01-PodLifecycleAndFailureStates`
2. `02-DiagnosingCrashLoopBackOffWithLogsAndEvents`
3. `03-ImagePullErrorsAndRegistryAuth`
4. `04-FixingImagePullBackOffViaImagePullSecret`
5. `05-EphemeralContainersAndKubectlDebug`
6. `06-AttachingAnEphemeralContainerToInspectEnvironment`
7. `07-PortForwardingAndLocalDebuggingTechniques`
8. `08-LiveDebugOfServiceViaPortForwardAndCurl`

## What You Learn

- how pod phases and container states map to normal vs failing behavior
- how to diagnose `ImagePullBackOff` and `CrashLoopBackOff` with events and logs
- how to use private registry credentials with `imagePullSecrets`
- how and when to use ephemeral containers for live troubleshooting
- how to use port-forward safely for local debugging of internal services

## Objectives

- identify startup failure signals from `kubectl get`, `describe`, and events
- isolate root cause quickly using logs and state transition details
- configure Docker registry secrets and attach them to pod specs
- debug a running workload without full redeploys when possible
- validate service behavior locally through `kubectl port-forward` and `curl`