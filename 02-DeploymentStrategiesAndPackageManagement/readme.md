# Deployment Strategies and Package Management

This module covers practical Kubernetes release strategies and packaging tools for safe, repeatable application delivery.

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
