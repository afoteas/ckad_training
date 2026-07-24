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

## CKAD Note

Flux and Argo CD architectures (source/kustomize/helm/notification controllers, `GitRepository`, `Kustomization`, `HelmRelease` CRDs) are **not** on the CKAD exam. Neither is the Flux↔Argo CD component mapping shown here — it is useful background, not testable material.

- The examinable overlap: the *Kustomize* concepts these tools automate (bases/overlays, `kubectl kustomize`, `kubectl apply -k`) and *Helm* releases (`helm install/upgrade`) are in-scope on their own.
- "Reconciliation is eventually consistent" is a real-world property of these controllers; on the exam you apply and verify changes yourself and there is no controller re-applying drift.
- Inspecting controller logs maps to the examinable `kubectl logs` skill, useful for any Pod.

## Key Takeaway

Flux (like Argo CD) uses a set of controllers to continuously reconcile Git into the cluster; for CKAD, only the underlying Kubernetes/Kustomize/Helm mechanics are testable — the GitOps controller architecture is background knowledge.
