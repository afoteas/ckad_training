# Policy Enforcement and Admission Control

This module focuses on governing what enters and runs in a Kubernetes cluster:

- admission controllers (mutating and validating) and the API request flow
- policy engines: OPA Gatekeeper (Rego) and Kyverno (YAML)
- writing and unit-testing Rego policies
- validating manifests locally with Conftest ("shift-left")
- continuous compliance reporting and auditing

## CKAD Exam Relevance

**Priority: Low — mostly beyond CKAD.** Admission controllers, OPA Gatekeeper, Kyverno, Rego, and Conftest are **CKS** (security specialist) and platform-engineering topics, not core CKAD material. The one broadly useful CKAD concept is understanding **where admission control sits in the API request flow** (authn → authz → admission → etcd) and the difference between **mutating** and **validating** webhooks. Read lesson 01 for that context; treat lessons 02–09 as production/CKS knowledge rather than CKAD exam prep.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Admission Controller Fundamentals | Medium | Know the API request flow and mutating vs validating admission |
| 02 | Creating a Simple Mutating Webhook | Low | Mutating webhooks/Kyverno are beyond CKAD scope |
| 03 | OPA Gatekeeper Architecture and Constraints | Low | Gatekeeper and Rego are CKS/platform topics |
| 04 | Enforcing Resource Limits with Gatekeeper | Low | Policy-as-code enforcement is not tested on CKAD |
| 05 | Kyverno Policy Language and Capabilities | Low | Kyverno is a CKS/platform tool, not CKAD |
| 06 | Blocking Privileged Pods with Kyverno | Low | Understand `securityContext.privileged`; the Kyverno policy itself is beyond CKAD |
| 07 | Rego Policy and Unit Test Writing | Low | Rego is not part of the CKAD curriculum |
| 08 | Validating Manifests Locally with Conftest | Low | Local policy testing is a CI/CKS practice |
| 09 | Continuous Compliance Reporting and Auditing | Low | Compliance auditing is an operations/CKS concern |

## Lessons

1. `01-AdmissionControllerFundamentals`
2. `02-CreatingASimpleMutatingWebhook`
3. `03-OPAGatekeeperArchitectureAndConstraints`
4. `04-EnforcingResourceLimitsWithGatekeeper`
5. `05-KyvernoPolicyLanguageAndCapabilities`
6. `06-BlockingPrivilegedPodsWithKyverno`
7. `07-RegoPolicyAndUnitTestWriting`
8. `08-ValidatingManifestsLocallyWithConftest`
9. `09-ContinuousComplianceReportingAndAuditing`

## Learning Objectives

- Explain where admission controllers sit in the API request flow.
- Distinguish mutating from validating admission and give examples of each.
- Inject standard labels into Pods automatically with a Kyverno mutating policy.
- Describe OPA Gatekeeper architecture: OPA engine, admission webhook, and audit.
- Enforce required CPU/memory limits with a Gatekeeper ConstraintTemplate and Constraint.
- Compare Kyverno (YAML) with Gatekeeper (Rego) and choose appropriately.
- Block privileged Pods with a Kyverno validation policy.
- Write Rego policies and unit test them.
- Validate manifests locally and in CI with Conftest.
- Set up continuous compliance reporting with Gatekeeper audit and Kyverno reports.
