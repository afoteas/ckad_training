# GitOps and Continuous Delivery on Kubernetes

This section introduces practical GitOps workflows for Kubernetes using Argo CD and Flux.

## CKAD Exam Relevance

**Priority: Low — optional for CKAD.** Argo CD, Flux, and GitOps reconciliation loops are valuable in production but are **not** typical CKAD hands-on tasks. The exam does not ask you to install GitOps controllers or configure sync policies. Skim this module for general awareness, or skip it entirely if you are short on study time. If you do read it, note that Kustomize overlays (also covered in module 02) are the only concept with direct CKAD overlap.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | GitOps Principles and Workflow Overview | Low | Conceptual awareness only; Git-as-source-of-truth is not tested hands-on |
| 02 | Installing Argo CD on a Cluster | Low | Installing Argo CD is not a CKAD task |
| 03 | Syncing a Sample App with Argo CD | Low | Argo CD Application CRDs are outside CKAD scope |
| 04 | Health Checks and Automated Rollbacks | Low | Rollback concepts overlap module 02; Argo-specific config is not tested |
| 05 | Git Revert Triggering Automatic Rollback | Low | GitOps rollback workflows are production-focused, not exam-focused |
| 06 | Introducing Flux and Reconciliation Loops | Low | Flux architecture is not on CKAD |
| 07 | Bootstrap Flux and Deploy via Kustomize | Low | Kustomize part overlaps module 02; Flux bootstrap is not tested |
| 08 | Multi-Environment Promotion Strategies | Low | Promotion pipelines are beyond CKAD |
| 09 | Image Update Automation and PR-Based Approval | Low | Automated image updates are not CKAD material |

## Course Outline

1. GitOps Principles and Workflow Overview
2. Installing Argo CD on a Cluster
3. Syncing a Sample App with Argo CD
4. Health Checks and Automated Rollbacks
5. Git Revert Triggering Automatic Rollback
6. Introducing Flux and Reconciliation Loops
7. Bootstrap Flux and Deploy via Kustomize
8. Multi-Environment Promotion Strategies
9. Image Update Automation and PR-Based Approval

## Learning Goals

- Understand core GitOps principles and desired-state reconciliation.
- Deploy and operate applications with Argo CD.
- Use health checks and rollback patterns to improve release safety.
- Learn Flux fundamentals and bootstrap workflows.
- Apply Kustomize for environment-based configuration.
- Implement promotion strategies across environments.
- Explore automated image updates with controlled approvals.

## Prerequisites

- Basic Kubernetes knowledge
- Access to a Kubernetes cluster
- `kubectl` configured for your cluster
- Basic familiarity with Git
