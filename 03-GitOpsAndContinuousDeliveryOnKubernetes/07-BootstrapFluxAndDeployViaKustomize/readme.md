# Bootstrap Flux and Deploy via Kustomize

## Overview

This lesson shows two ways to get Flux running and then use Kustomize overlays to deploy a simple app from Git.

The app in this folder uses a base plus `dev` and `prod` overlays. The deployment image is a public `nginx` image so it can be pulled in a normal cluster without extra registry setup.

## What You Should Know

- Flux is a pull-based GitOps controller.
- Kustomize lets you keep a shared base and small environment-specific overlays.
- `bootstrap` installs Flux and wires it to a repo in one step.
- `install` only installs the controllers; you then add sources and kustomizations yourself.
- Flux typically watches a `GitRepository` and applies a `Kustomization`.

## Prerequisites

- A working `kubectl` context.
- Flux CLI installed locally.
- Access to the Git repository you want Flux to read.

Install the CLI on Linux:

```bash
curl -s https://fluxcd.io/install.sh | sudo bash
flux --version
flux check --pre
```

Verify your cluster access:

```bash
kubectl config current-context
kubectl get nodes
```

## Setup Option 1: Bootstrap Flux

Use bootstrap when you want the fastest path. It installs the controllers and creates the initial repo wiring for you.

```bash
flux bootstrap github \
  --owner afoteas \
  --repository ckad_training \
  --branch main \
  --path GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize \
  --personal
```

After bootstrap, Flux already has an SSH-based source in the `flux-system` namespace.

## Setup Option 2: Install Flux, Then Add Sources Manually

Use this when you want to separate controller installation from repository wiring.

```bash
flux install
```

Then create your own Git source and Kustomization. The source example below uses SSH and expects an auth Secret named `repo-auth`.

```bash
flux create source git ckad-training-repo \
  --url=ssh://git@github.com/afoteas/ckad_training \
  --secret-ref=repo-auth \
  --branch=main \
  --interval=1m \
  --export | kubectl apply -f -

flux create kustomization guestbook-dev \
  --source=GitRepository/ckad-training-repo \
  --path=./GitOpsAndContinuousDeliveryOnKubernetes/07-BootstrapFluxAndDeployViaKustomize/apps/guestbook/overlays/dev \
  --prune=true \
  --interval=5m \
  --target-namespace=guestbook-dev \
  --export | kubectl apply -f -
```

Create the namespace before reconciling:

```bash
kubectl create namespace guestbook-dev --dry-run=client -o yaml | kubectl apply -f -
```

## Repository Layout

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

## App Files in This Lesson

- [apps/guestbook/base/kustomization.yaml](apps/guestbook/base/kustomization.yaml)
- [apps/guestbook/base/deployment.yaml](apps/guestbook/base/deployment.yaml)
- [apps/guestbook/base/service.yaml](apps/guestbook/base/service.yaml)
- [apps/guestbook/overlays/dev/kustomization.yaml](apps/guestbook/overlays/dev/kustomization.yaml)
- [apps/guestbook/overlays/dev/patch-replicas.yaml](apps/guestbook/overlays/dev/patch-replicas.yaml)
- [apps/guestbook/overlays/prod/kustomization.yaml](apps/guestbook/overlays/prod/kustomization.yaml)
- [apps/guestbook/overlays/prod/patch-replicas.yaml](apps/guestbook/overlays/prod/patch-replicas.yaml)

## How the App Is Wired

- The base defines the Deployment and Service.
- The `dev` overlay keeps a single replica.
- The `prod` overlay scales the workload higher.
- The lesson uses `nginx:1.27-alpine` so the image is public and easy to pull.

## Working With Flux

If you used bootstrap:

```bash
flux reconcile kustomization guestbook-dev -n flux-system
flux get sources git -A
flux get kustomizations -A
```

If you used the manual install path:

```bash
flux reconcile source git ckad-training-repo -n flux-system
flux reconcile kustomization guestbook-dev -n flux-system
```

The first command tells Flux to fetch the latest commit from the GitRepository again. Use it after you push a change to Git, or when you want to force Flux to re-check the repo immediately instead of waiting for the next interval.

The second command tells Flux to re-run the Kustomization for the `dev` overlay. It reads the source artifact, builds the manifests with Kustomize, applies them to the cluster, and then runs health checks on the resulting workload.

For the manual path to work, these must already exist:

- the `ckad-training-repo` GitRepository object
- the `guestbook-dev` Kustomization object
- the `guestbook-dev` namespace
- a Ready Git source with valid SSH auth or repo credentials

In both cases, the namespace must exist and the source must be ready before the Kustomization can finish.

## Verify the Deployment

```bash
kubectl get pods -n guestbook-dev
kubectl get deploy,svc -n guestbook-dev
kubectl rollout status deployment/guestbook-ui -n guestbook-dev
```

## Troubleshooting

- If a Git source fails with a TLS certificate error, Flux is usually hitting a corporate proxy or CA trust issue.
- If the pod stays in `ImagePullBackOff`, check the image name and make sure it is publicly reachable.
- If a Kustomization waits too long, confirm the target namespace exists and the source is `Ready`.

## Practical Tips

- Keep base and overlays small and predictable.
- Use one overlay per environment.
- Prefer a public image for demos unless the lesson is specifically about registry auth.

## CKAD Note

Bootstrapping Flux and the `flux` CLI (`flux bootstrap`, `flux install`, `flux create source/kustomization`, `flux reconcile`) are **not** on the CKAD exam — that is GitOps tooling.

- **Kustomize itself IS examinable**, and this chapter is a great excuse to drill it: understand `base/` + `overlays/dev|prod`, the overlay `kustomization.yaml` (`resources`, `patches`/`patchesStrategicMerge`, `namespace`, `namePrefix`, `images`), and replica patches.
- Practice the exam-native commands the Flux Kustomization runs for you: `kubectl kustomize <dir>` to render and `kubectl apply -k <dir>` to apply.
- Also in-scope from this lab: namespace creation (`kubectl create namespace`), the idempotent `--dry-run=client -o yaml | kubectl apply -f -` pattern, and verifying with `kubectl get pods/deploy/svc` and `kubectl rollout status`.

## Key Takeaway

Flux can bootstrap itself and deploy a Kustomize app straight from Git, but for CKAD the durable skill is Kustomize — building bases/overlays and applying them with `kubectl apply -k` / `kubectl kustomize` — not the Flux CLI wiring around it.
