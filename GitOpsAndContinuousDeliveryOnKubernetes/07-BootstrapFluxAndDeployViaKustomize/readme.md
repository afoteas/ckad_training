# Bootstrap Flux and Deploy via Kustomize

## Overview

Bootstrapping Flux installs controllers and wires your cluster to a Git repository so that Kustomize manifests are applied automatically.

## What You Should Know

- Bootstrap creates Flux manifests in your repo.
- Kustomize overlays are ideal for environment-specific changes.
- Repository structure determines maintainability as scale grows.
- PR-driven updates become the default change path after bootstrap.

## Install Flux CLI (Linux)

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version
flux check --pre
```

If you do not have cluster access configured yet, ensure your kube context works first:

```bash
kubectl config current-context
kubectl get nodes
```

## Typical Bootstrap Steps

1. Install flux CLI locally.
2. Authenticate to Git provider.
3. Bootstrap Flux controllers.
4. Add app base and overlays.
5. Create Flux source and kustomization.
6. Verify reconciliation.

## Example Commands

```bash
flux check
export GITHUB_TOKEN=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
flux bootstrap github \
  --owner afoteas \
  --repository ckad_training \
  --branch main \
  --path GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize \
  --personal

flux get sources git -A
flux get kustomizations -A
```

## Example Base and Overlays

Minimal structure:

```text
repo/
  apps/
    guestbook/
      base/
        deployment.yaml
        service.yaml
        kustomization.yaml
      overlays/
        dev/
          kustomization.yaml
          patch-replicas.yaml
        prod/
          kustomization.yaml
          patch-replicas.yaml
```

Created app manifests in this lesson:

- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/kustomization.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/kustomization.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/deployment.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/deployment.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/service.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/base/service.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev/kustomization.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev/kustomization.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev/patch-replicas.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev/patch-replicas.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/prod/kustomization.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/prod/kustomization.yaml)
- [GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/prod/patch-replicas.yaml](GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/prod/patch-replicas.yaml)

Create Flux source and Kustomization directly (no clusters folder needed):

```bash
flux create kustomization guestbook-dev \
  --source=GitRepository/flux-system \
  --path=./GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev \
  --prune=true \
  --interval=5m \
  --target-namespace=guestbook-dev \
  --export | kubectl apply -f -
```

Create the target namespace before reconciling:

```bash
kubectl create namespace guestbook-dev --dry-run=client -o yaml | kubectl apply -f -
```

Then use the existing bootstrap-created SSH source named `flux-system`.

Apply and verify:

```bash
flux reconcile kustomization guestbook-dev -n flux-system
kubectl get kustomizations -n flux-system
kubectl get deploy,svc -n guestbook-dev
```

## Practical Tips

- Keep clusters or environments under dedicated top-level folders.
- Validate Kustomize output locally before pushing.
- Use naming conventions that map clearly to environment and team.
