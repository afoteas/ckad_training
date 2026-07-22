# Services, Ingress, and Networking Fundamentals

This module covers how workloads are exposed and how traffic is controlled inside and outside the cluster:

- Service types (ClusterIP, NodePort, LoadBalancer, ExternalName)
- headless Services for StatefulSet Pod identity
- Ingress controllers and resources for Layer 7 routing (TLS, host, path)
- NetworkPolicies for traffic segmentation
- service discovery via DNS and environment variables

## CKAD Exam Relevance

**Priority: High.** Networking is a core CKAD domain. You should be able to create a **ClusterIP** and **NodePort** Service, expose a Deployment, write an **Ingress** with host/path rules and TLS, define **NetworkPolicies** with ingress/egress rules and selectors, and resolve Services by their **DNS** name (`service.namespace.svc.cluster.local`). LoadBalancer, ExternalTrafficPolicy, and headless/StatefulSet details are useful but tested more lightly. Environment-variable discovery is mostly background knowledge.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Service Types Explained | **High** | Know ClusterIP/NodePort/LoadBalancer/ExternalName and when to use each |
| 02 | Creating ClusterIP and NodePort Services | **High** | Writing and testing Service manifests is a common exam task |
| 03 | LoadBalancer Services and ExternalTrafficPolicy | Medium | Know what LoadBalancer does; `externalTrafficPolicy` is a nuance |
| 04 | Headless Services and StatefulSets | Medium | Know `clusterIP: None` and stable Pod DNS names |
| 05 | Ingress Controllers and Resources | **High** | Controller vs resource distinction is core Ingress knowledge |
| 06 | Deploying NGINX Ingress and Basic Routing | **High** | Hands-on Ingress with host-based routing |
| 07 | Advanced Ingress: TLS, Host, and Path Rules | **High** | TLS secrets and host/path routing appear on CKAD |
| 08 | Network Policies Overview | **High** | podSelector, policyTypes, ingress/egress rules are tested |
| 09 | Restricting Traffic with Network Policies | **High** | Hands-on default-deny and label-based allow rules |
| 10 | Service Discovery via DNS & Env Vars | **High** | DNS names and FQDN cross-namespace resolution are essential |

## Lessons

1. `01-ServiceTypesExplained`
2. `02-CreatingClusterIPAndNodePortServices`
3. `03-LoadBalancerServicesAndExternalTrafficPolicy`
4. `04-HeadlessServicesAndStatefulSets`
5. `05-IngressControllersAndResources`
6. `06-DeployingNGINXIngressAndBasicRouting`
7. `07-AdvancedIngressTLSHostAndPathRules`
8. `08-NetworkPoliciesOverview`
9. `09-RestrictingTrafficWithNetworkPolicies`
10. `10-ServiceDiscoveryViaDNSAndEnvVars`

## Learning Objectives

- Compare the four Service types and choose the right one per use case.
- Create ClusterIP and NodePort Services and verify internal/external access.
- Explain LoadBalancer provisioning and the `externalTrafficPolicy` trade-off.
- Use headless Services with StatefulSets for stable per-Pod DNS identity.
- Distinguish Ingress controllers from Ingress resources.
- Deploy the NGINX ingress controller and route by hostname.
- Configure TLS termination and host/path-based Ingress rules.
- Segment cluster traffic with NetworkPolicies (ingress and egress).
- Enforce least-privilege network access with label-based policies.
- Resolve Services via DNS (short name and FQDN) and environment variables.
