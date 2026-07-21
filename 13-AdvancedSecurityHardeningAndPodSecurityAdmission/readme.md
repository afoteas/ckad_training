# Advanced Security Hardening and Pod Security Admission

This module focuses on advanced Kubernetes security controls:

- Pod Security Admission (PSA) and security standards
- Linux security profiles (seccomp and AppArmor)
- image signing and verification with Cosign and admission webhooks
- advanced RBAC patterns including aggregation, impersonation, and scoped service accounts

## CKAD Exam Relevance

**Priority: Low–Medium — study selectively.** Most of this module goes beyond CKAD. The exam-relevant parts are: **Pod Security Standards** concepts (lesson 01), writing a **restricted-compliant securityContext** (lesson 02), and basic **`seccompProfile: RuntimeDefault`** (lesson 03). Cosign, image policy webhooks, RBAC aggregation, and impersonation (lessons 05–08) are production security topics not tested on CKAD. Read lessons 01–03 and skim the rest. Your deeper securityContext practice in module 11 matters more for the exam.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Pod Security Admission and Standards | Medium | Know `privileged`/`baseline`/`restricted` and PSA namespace labels |
| 02 | Enforcing Restricted Policy in a Namespace | **High** | Writing restricted-compliant `securityContext` is the main exam takeaway |
| 03 | Seccomp and AppArmor Profiles | Medium | Know `seccompProfile.type: RuntimeDefault`; AppArmor is rarely hands-on |
| 04 | Applying a Localhost seccomp Profile to a Pod | Low | Custom seccomp JSON on nodes is beyond CKAD |
| 05 | Image Signing and Verification with Cosign | Low | Supply chain signing is not CKAD material |
| 06 | Verifying Image Signatures via ImagePolicyWebhook | Low | Image policy webhooks are not tested on CKAD |
| 07 | Advanced RBAC Aggregation and Impersonation | Low | Aggregation and impersonation are beyond CKAD scope |
| 08 | Creating Aggregated Roles and Scoped SA | Low | Basic RBAC is in module 11; aggregation is not tested |

## Lessons

1. `01-PodSecurityAdmissionAndStandards`
2. `02-EnforcingRestrictedPolicyInANamespace`
3. `03-SeccompAndAppArmorProfiles`
4. `04-ApplyingALocalhostSeccompProfileToAPod`
5. `05-ImageSigningAndVerificationWithCosign`
6. `06-VerifyingImageSignaturesViaImagePolicyWebhook`
7. `07-AdvancedRBACAggregationAndImpersonation`
8. `08-CreatingAggregatedRolesAndScopedSA`

## Learning Objectives

- Explain Pod Security Admission modes and the three Pod Security Standards levels.
- Enforce a `restricted` policy on a namespace using labels.
- Configure seccomp and AppArmor profiles on Pods and containers.
- Apply a localhost seccomp profile to harden a workload.
- Sign container images with Cosign and verify signatures at deploy time.
- Configure image signature verification using an ImagePolicyWebhook.
- Use RBAC aggregation and impersonation for advanced access patterns.
- Create aggregated ClusterRoles and scoped ServiceAccounts for least-privilege access.
