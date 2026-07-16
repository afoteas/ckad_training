# APIs, Custom Resources, and Operator Patterns

This module covers advanced kubectl usage, direct Kubernetes API access, Custom Resource Definitions (CRDs), operator patterns, and API version lifecycle management.

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