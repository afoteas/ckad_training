# Debugging and Troubleshooting Applications

This module focuses on practical Kubernetes troubleshooting for pod startup failures, crash loops, image pull issues, live debugging, and safe local access to in-cluster services.

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