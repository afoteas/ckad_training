# Introducing Flux and Reconciliation Loops

## Overview

Flux is a GitOps toolkit that continuously reconciles Kubernetes resources from Git and supports Kustomize and Helm workflows.

## What You Should Know

- Flux controllers watch source repositories and apply changes on intervals.
- Reconciliation is eventually consistent, not instant.
- Source, Kustomization, and HelmRelease are key Flux custom resources.
- Drift correction is a default strength of reconciliation-based systems.

## Core Components

- source-controller for Git and Helm sources.
- kustomize-controller for Kustomize applies.
- helm-controller for Helm releases.
- notification-controller for alerts and events.

## Argo CD Core Components (Equivalent View)

- argocd-repo-server fetches Git or Helm sources and renders manifests.
- argocd-application-controller runs reconciliation and sync logic.
- argocd-server provides API, UI, and CLI entrypoint.
- argocd-redis provides cache and internal state backing.
- argocd-dex-server handles SSO/OIDC when enabled.
- argocd-applicationset-controller generates multiple Application resources from templates.

## Flux to Argo CD Mapping

- Flux source-controller -> Argo CD argocd-repo-server.
- Flux kustomize-controller and helm-controller -> Argo CD argocd-application-controller.
- Flux notification-controller -> Argo CD notifications component.
- Argo CD argocd-server has no strict Flux core equivalent (built-in UI/API).

## Practical Tips

- Start with shorter intervals in labs and longer in production.
- Keep one Kustomization per bounded app or domain.
- Monitor controller logs when resources are not applying.
