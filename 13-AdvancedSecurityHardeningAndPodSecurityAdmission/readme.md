# Advanced Security Hardening and Pod Security Admission

This module focuses on advanced Kubernetes security controls:

- Pod Security Admission (PSA) and security standards
- Linux security profiles (seccomp and AppArmor)
- image signing and verification with Cosign and admission webhooks
- advanced RBAC patterns including aggregation, impersonation, and scoped service accounts

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
