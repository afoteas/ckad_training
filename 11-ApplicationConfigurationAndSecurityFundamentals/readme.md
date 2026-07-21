# Application Configuration and Security Fundamentals

This module covers how Kubernetes applications are configured, secured, and granted identity — the building blocks of almost every CKAD task involving Pod specs.

## CKAD Exam Relevance

**Priority: Very High — core exam material.** This is one of the most important modules for CKAD. You will almost certainly need to create or edit **ConfigMaps** and **Secrets** (as env vars or mounted volumes), configure **securityContext** (`runAsNonRoot`, `capabilities.drop`, `readOnlyRootFilesystem`), set up **ServiceAccounts** with **Role/RoleBinding**, and use the **Downward API**. Lessons 01–03 and 05–07 are must-study. Encrypting secrets at rest (lesson 04) and live config reload (lesson 08) are useful in production but rarely tested hands-on. If you only have time for one configuration module, make it this one.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | ConfigMap and Environment Variable Management | **High** | Creating ConfigMaps and injecting as env vars is a core exam skill |
| 02 | Creating and Mounting ConfigMaps | **High** | Volume-mounting ConfigMaps as files is regularly tested |
| 03 | Secret Management | **High** | Creating Secrets and mounting/injecting them is a common hands-on task |
| 04 | Encrypting Secrets at Rest | Low | Encryption-at-rest configuration is cluster-admin level, not CKAD |
| 05 | SecurityContexts and Pod Security Standards | **High** | `runAsNonRoot`, `capabilities.drop`, `readOnlyRootFilesystem` are heavily tested |
| 06 | Configuring ServiceAccounts and RBAC for Applications | **High** | ServiceAccount + Role + RoleBinding manifests appear on most CKAD exams |
| 07 | The Downward API and Dynamic Config | **High** | Exposing Pod metadata via `fieldRef` and `resourceFieldRef` is tested |
| 08 | Implementing a Live Config Reload Pattern | Low | Config reload sidecars are production patterns, not exam tasks |

## Lesson Order

1. `01-ConfigMapAndEnvironmentVariableManagement`
2. `02-CreatingAndMountingConfigMaps`
3. `03-SecretManagement`
4. `04-EncryptingSecretsAtRest`
5. `05-SecurityContextsAndPodSecurityStandards`
6. `06-ConfiguringServiceAccountsAndRBACForApplications`
7. `07-TheDownwardAPIAndDynamicConfig`
8. `08-ImplementingALiveConfigReloadPattern`

## What You Learn

- inject configuration via ConfigMaps and environment variables
- mount ConfigMaps and Secrets as files in Pods
- manage sensitive data with Secrets and understand their limitations
- harden workloads with securityContext and Pod Security Standards
- grant least-privilege access with ServiceAccounts, Roles, and RoleBindings
- expose Pod metadata to containers via the Downward API

## Objectives

- create ConfigMaps and inject them as env vars or volume mounts
- create Secrets and mount them securely in application Pods
- configure securityContext for non-root, least-privilege containers
- create a ServiceAccount and bind it to a Role with a RoleBinding
- use the Downward API to pass Pod labels and annotations to containers
