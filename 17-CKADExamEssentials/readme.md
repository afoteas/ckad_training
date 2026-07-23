# CKAD Exam Essentials

This module is your **exam preparation hub**: format, time management, imperative `kubectl` shortcuts, documentation navigation, verification habits, and timed practice scenarios.

It does not replace the technical modules — it shows **how to study them** and **how to work under exam conditions**.

## CKAD Study Path — Modules to Prioritize

Study these modules in order. Links point to each module's readme (with per-lesson CKAD relevance tables).

| Priority | Module | Focus |
|----------|--------|-------|
| **Foundation** | [00-KubernetesClusterArchitecture](../00-KubernetesClusterArchitecture/readme.md) | Control plane, nodes, add-ons, request flow |
| **Start** | [17-CKADExamEssentials](readme.md) | Exam mechanics (this module) |
| **1** | [01-WorkloadandContainerImageFundamentals](../01-WorkloadandContainerImageFundamentals/readme.md) | Workloads, multicontainer Pods, volumes, labels, DaemonSet |
| **2** | [11-ApplicationConfigurationAndSecurityFundamentals](../11-ApplicationConfigurationAndSecurityFundamentals/readme.md) | ConfigMap, Secret, securityContext, RBAC, Downward API |
| **3** | [16-ServicesIngressAndNetworkingFundamentals](../16-ServicesIngressAndNetworkingFundamentals/readme.md) | Services, Ingress, NetworkPolicy, DNS |
| **4** | [05-ObservabilityLoggingAndProbes](../05-ObservabilityLoggingAndProbes/readme.md) | Liveness, readiness, startup probes, logs, events |
| **5** | [08-DebuggingAndTroubleshootingApplications](../08-DebuggingAndTroubleshootingApplications/readme.md) | CrashLoop, ImagePull, ephemeral debug, port-forward |
| **6** | [12-ResourceLimitsSchedulingAndAutoscaling](../12-ResourceLimitsSchedulingAndAutoscaling/readme.md) | Requests/limits, Quota, affinity, taints, HPA |
| **7** | [02-DeploymentStrategiesAndPackageManagement](../02-DeploymentStrategiesAndPackageManagement/readme.md) | Rollback, Helm, Kustomize |
| **8** | [06-StatefulApplicationsAndDataPersistence](../06-StatefulApplicationsAndDataPersistence/readme.md) | StatefulSet, PVC/PV, Jobs, CronJobs, StorageClass |
| **9** | [07-APIsCustomResourcesAndOperatorPatterns](../07-APIsCustomResourcesAndOperatorPatterns/readme.md) | JSONPath, patch, scale (lessons 01–02) |
| **10** | [10-BatchAndEventDrivenWorkloads](../10-BatchAndEventDrivenWorkloads/readme.md) | Jobs/CronJobs deep dive (if module 06 lessons 05–06 are not enough) |

### Skim or skip for CKAD (useful later for production / CKS)

| Module | Why lower priority |
|--------|-------------------|
| [03-GitOpsAndContinuousDeliveryOnKubernetes](../03-GitOpsAndContinuousDeliveryOnKubernetes/readme.md) | Argo CD / Flux — not CKAD hands-on |
| [04-LocalDevelopmentTestingAndContinuousIntegration](../04-LocalDevelopmentTestingAndContinuousIntegration/readme.md) | Skaffold, CI pipelines — not exam topics |
| [09-MonitoringAlertingAndPerformanceOptimization](../09-MonitoringAlertingAndPerformanceOptimization/readme.md) | Prometheus/Grafana depth — beyond CKAD |
| [13-AdvancedSecurityHardeningAndPodSecurityAdmission](../13-AdvancedSecurityHardeningAndPodSecurityAdmission/readme.md) | Mostly CKS (seccomp, Cosign, PSA enforcement) |
| [14-AdvancedSchedulingAndScalabilityPatterns](../14-AdvancedSchedulingAndScalabilityPatterns/readme.md) | VPA, descheduler, topology spread — nice extras |
| [15-PolicyDrivenGovernanceAndAdmissionControl](../15-PolicyDrivenGovernanceAndAdmissionControl/readme.md) | Gatekeeper/Kyverno — CKS territory |

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Exam Format and Strategy | **High** | Time budget, question weighting, when to skip |
| 02 | Imperative kubectl and Manifest Generation | **High** | Fastest way to produce valid YAML under pressure |
| 03 | Using Kubernetes Documentation During the Exam | **High** | Official docs are allowed — know how to search them |
| 04 | Post-Task Verification Checklist | **High** | Catch mistakes before losing points |
| 05 | Timed Practice Scenarios | **High** | Simulate exam tasks end-to-end |

## Lessons

1. `01-ExamFormatAndStrategy`
2. `02-ImperativeKubectlAndManifestGeneration`
3. `03-UsingKubernetesDocumentationDuringTheExam`
4. `04-PostTaskVerificationChecklist`
5. `05-TimedPracticeScenarios`

## Learning Objectives

- Budget time across ~15–20 tasks in 2 hours.
- Generate starter YAML with `kubectl create/run --dry-run=client -o yaml`.
- Find API fields quickly in kubernetes.io/docs.
- Verify every task with get/describe/logs/endpoints before moving on.
- Complete mixed scenarios under a 10-minute timer.
