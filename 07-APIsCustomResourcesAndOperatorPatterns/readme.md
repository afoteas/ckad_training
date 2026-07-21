# APIs, Custom Resources, and Operator Patterns

This module covers advanced kubectl usage, direct Kubernetes API access, Custom Resource Definitions (CRDs), operator patterns, and API version lifecycle management.

## CKAD Exam Relevance

**Priority: Medium.** Lessons 01–02 are **high value** for CKAD: `kubectl` JSONPath output, `kubectl patch`, `kubectl scale`, and piping JSON to `jq` save time during the exam. CRDs (lessons 05–06) may appear as a "create a custom resource" task — know the basic CRD structure. Client-go, Kubebuilder, and operator scaffolding (lessons 03–04, 07–08) are **not** CKAD topics. API deprecation awareness (lesson 09) is useful background but rarely tested hands-on. Focus on kubectl power-user skills first.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Power User Kubectl JSONPath and Patching | **High** | JSONPath, `kubectl patch`, and `kubectl scale` save critical exam time |
| 02 | Efficient Debugging with Kubectl and Jq | **High** | `kubectl -o json` + `jq` for fast troubleshooting during the exam |
| 03 | Accessing the Kubernetes API with Client-Go | Low | Go client programming is not CKAD scope |
| 04 | Creating Pods Programmatically in Go | Low | Writing Go code to create Pods is not tested |
| 05 | Custom Resource Definitions (CRDs) | Medium | Know CRD structure; may need to create or apply a basic CRD |
| 06 | Defining and Applying a CRD | Medium | Hands-on CRD + custom resource creation is occasionally tested |
| 07 | Operator Pattern Fundamentals | Low | Operator reconcile loop is conceptual, not hands-on CKAD |
| 08 | Scaffolding an Operator with Kubebuilder | Low | Kubebuilder scaffolding is far beyond CKAD |
| 09 | Managing API Versions and Deprecations | Low | Useful for cluster upgrades; rarely a CKAD task |

## Lesson Order

1. `01-PowerUserKubectlJSONPathAndPatching`
2. `02-EfficientDebuggingWithKubectlAndJq`
3. `03-AccessingTheKubernetesAPIWithClientGo`
4. `04-CreatingPodsProgrammaticallyInGo`
5. `05-CustomResourceDefinitionsCRDs`
6. `06-DefiningAndApplyingACRD`
7. `07-OperatorPatternFundamentals`
8. `08-ScaffoldingAnOperatorWithKubebuilder`
9. `09-ManagingAPIVersionsAndDeprecations`

## What You Learn

- query Kubernetes objects precisely with JSONPath
- make fast live changes with `kubectl patch` and `kubectl scale`
- extract structured debugging data with `kubectl -o json` and `jq`
- understand how kubectl maps to the Kubernetes REST API
- use `client-go` for typed API access in Go programs
- extend Kubernetes with CRDs and custom resources
- understand the operator reconcile loop and its building blocks
- scaffold an operator project and connect spec to controller logic
- manage API deprecations before upgrades break manifests

## Objectives

- build custom command-line views of pods, services, and nodes
- patch or scale a live workload without full manifest replacement
- parse cluster state programmatically for scripts and troubleshooting
- explain API groups, versions, authentication, and typed clients
- describe how CRDs define new resource types and evolve safely
- create and query custom resources with kubectl
- explain how operators declare, watch, and reconcile desired state
- summarize the workflow for scaffolding and testing a controller project
- identify, audit, and migrate deprecated Kubernetes APIs