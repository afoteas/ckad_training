# Resource Limits, Scheduling, and Autoscaling

This module focuses on three core Kubernetes operations themes:

- resource governance with requests, limits, quotas, and limit ranges
- placement control with selectors, affinity, taints, and tolerations
- dynamic scaling with Horizontal Pod Autoscaler (HPA) and Vertical Pod Autoscaler (VPA)

## CKAD Exam Relevance

**Priority: High.** CKAD frequently tests **resource requests and limits**, **LimitRange**, **ResourceQuota**, **nodeSelector**, **nodeAffinity**, **taints/tolerations**, and **HPA** configuration. You should be able to write a Pod with CPU/memory requests, label a node and schedule a Pod onto it, taint a node and add a matching toleration, and create an HPA targeting CPU utilization. Lessons 01–09 are exam-relevant. **VPA** (lesson 10) is conceptual only — know how it differs from HPA but do not prioritize hands-on practice.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Understanding Resource Requests and Limits | **High** | Requests vs limits fundamentals are essential for every CKAD exam |
| 02 | Setting Requests and Limits in Pods | **High** | Writing `resources.requests/limits` in Pod YAML is regularly tested |
| 03 | Resource Quotas and Limit Ranges | **High** | ResourceQuota and LimitRange manifests appear on CKAD |
| 04 | Scheduling with Node Selectors and Affinity | **High** | nodeSelector and nodeAffinity theory is core scheduling knowledge |
| 05 | Node Selector and Affinity Rules in Action | **High** | Hands-on affinity manifests with `required` and `preferred` rules |
| 06 | Taints and Tolerations Explained | **High** | Taint effects, toleration operators, and taints vs affinity are tested |
| 07 | Tainting Nodes and Applying Tolerations | **High** | `kubectl taint` and writing tolerations in Pod specs are common tasks |
| 08 | Horizontal Pod Autoscaling Basics | **High** | HPA YAML structure, metric types, and prerequisites are exam topics |
| 09 | Implementing HPA in a Live App | **High** | Hands-on HPA with CPU utilization and metrics-server |
| 10 | Vertical Pod Autoscaling Basics | Low | VPA is conceptual only — know it adjusts requests/limits, not replicas |

## Lessons

1. `01-UnderstandingResourceRequestsAndLimits`
2. `02-SettingRequestsAndLimitsInPods`
3. `03-ResourceQuotasAndLimitRanges`
4. `04-SchedulingWithNodeSelectorsAndAffinity`
5. `05-NodeSelectorAndAffinityRulesInAction`
6. `06-TaintsAndTolerationsExplained`
7. `07-TaintingNodesAndApplyingTolerations`
8. `08-HorizontalPodAutoscalingBasics`
9. `09-ImplementingHPAInALiveApp`
10. `10-VerticalPodAutoscalingBasics`

## Learning Objectives

- Explain the difference between resource requests and limits.
- Set resource constraints in Pod and Deployment manifests.
- Use ResourceQuota and LimitRange to govern multi-tenant namespaces.
- Control scheduling with node labels, selectors, and affinity rules.
- Isolate workloads with taints and tolerations.
- Configure and validate HPA behavior using CPU utilization.
- Explain how VPA differs from HPA and when to use vertical scaling.
