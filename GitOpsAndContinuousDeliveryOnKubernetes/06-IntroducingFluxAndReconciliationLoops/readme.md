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

## Practical Tips

- Start with shorter intervals in labs and longer in production.
- Keep one Kustomization per bounded app or domain.
- Monitor controller logs when resources are not applying.
