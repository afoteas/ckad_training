# Resource Limits, Scheduling, and Autoscaling

This module focuses on three core Kubernetes operations themes:

- resource governance with requests, limits, quotas, and limit ranges
- placement control with selectors, affinity, taints, and tolerations
- dynamic scaling with Horizontal Pod Autoscaler (HPA)

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

## Learning Objectives

- Explain the difference between resource requests and limits.
- Set resource constraints in Pod and Deployment manifests.
- Use ResourceQuota and LimitRange to govern multi-tenant namespaces.
- Control scheduling with node labels, selectors, and affinity rules.
- Isolate workloads with taints and tolerations.
- Configure and validate HPA behavior using CPU utilization.
