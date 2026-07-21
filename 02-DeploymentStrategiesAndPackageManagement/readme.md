# Deployment Strategies and Package Management

This module covers practical Kubernetes release strategies and packaging tools for safe, repeatable application delivery.

## CKAD Exam Relevance

**Priority: High.** CKAD regularly tests Deployment rollout controls (`maxSurge`, `maxUnavailable`, `revisionHistoryLimit`), `kubectl rollout status/history/undo`, and packaging with **Helm** and **Kustomize**. You should be able to install/upgrade a Helm chart and apply Kustomize overlays without hesitation. Blue/green and canary are more conceptual on the exam, but understanding them helps with Service selector switches and incremental rollouts. Focus on lessons 05–06 (rollbacks) and 07–10 (Helm/Kustomize) for the strongest exam return.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | Blue/Green Deployment Pattern | Medium | Conceptual — understand traffic cutover; may help with Service selector tasks |
| 02 | Implementing Blue/Green with Service Selector Switch | Medium | Service label switching is occasionally tested; good pattern knowledge |
| 03 | Canary Deployments and Progressive Delivery | Low | Conceptual only; advanced traffic splitting is not typical CKAD |
| 04 | Implementing Canary Rollout with Percentage-Based Traffic | Low | Requires service mesh or ingress weighting — beyond standard CKAD scope |
| 05 | Managing Rollbacks and Rollout History | **High** | `kubectl rollout history/undo` and `revisionHistoryLimit` are exam staples |
| 06 | Performing a Rollback After Failed Rollout | **High** | Hands-on rollback after a bad update is a common troubleshooting scenario |
| 07 | Helm Basics and Chart Structure | **High** | Chart structure, `values.yaml`, and `helm install/upgrade` appear on CKAD |
| 08 | Installing and Upgrading an App with Helm | **High** | Practical Helm install, upgrade, and rollback commands are tested |
| 09 | Kustomize for Overlay Management | **High** | `kustomization.yaml`, bases, and overlays are regular CKAD tasks |
| 10 | Implementing Kustomize Overlays for Dev and Prod | **High** | Environment-specific patches and overlays are hands-on exam material |

## Lesson Order

1. `01-BlueGreenDeploymentPattern`
2. `02-ImplementingBlueGreenWithServiceSelectorSwitch`
3. `03-CanaryDeploymentsAndProgressiveDelivery`
4. `04-ImplementingCanaryRolloutWithPercentageBasedTraffic`
5. `05-ManagingRollbacksAndRolloutHistory`
6. `06-PerformingARollbackAfterFailedRollout`
7. `07-HelmBasicsAndChartStructure`
8. `08-InstallingAndUpgradingAnAppWithHelm`
9. `09-KustomizeForOverlayManagement`
10. `10-ImplementingKustomizeOverlaysForDevAndProdEnvironments`

## What You Learn

- Blue/Green and canary release strategies
- rollout monitoring and rollback execution
- Helm chart structure and release management
- Kustomize overlays for environment-specific configuration

## Suggested Progression

1. Learn strategy concepts first (Blue/Green and Canary).
2. Practice rollout controls and rollback safety.
3. Move into package management with Helm.
4. Finish with Kustomize overlays for multi-environment promotion.


## Objectives

- describe blue/green deployments and service cut‑over techniques
- implement the deployment of two application versions and switch traffic using Service selectors
- compare canary and blue/green deployments along with traffic‑splitting options
- implement deployment strategies using maxUnavailable, maxSurge, and incremental updates
- analyze rollout history and perform a rollback to a previous revision
- perform a failed update, detect the issue, and roll back to a previous revision
- describe Helm architecture, charts, and release workflow
- install a public chart and perform an upgrade
- use Kustomize bases and overlays for environment‑specific manifests
- implement overlays for development and production environments and deploy them
