# Live Coding with Skaffold Dev Loop

This guide shows how Skaffold shortens the Kubernetes development feedback loop by automating build, push, and deploy on every code change.

## Why This Matters

In a manual workflow, each small change often requires:

- rebuilding an image
- pushing the image to a registry
- redeploying with kubectl

That cycle is slow and interrupts experimentation.

Skaffold solves this by continuously watching your source and automating the loop so you get near-instant iteration.

## What Skaffold Is

Skaffold is an open-source Kubernetes development tool that automates repetitive tasks:

- image build
- image push
- manifest deployment

It supports multiple builders, including:

- Docker
- Kaniko
- Buildpacks

## Installation

```bash
# Download and install Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x skaffold
sudo mv skaffold /usr/local/bin/
```

## Prerequisites

- A running Kubernetes cluster (kind or minikube)
- kubectl configured for that cluster
- Container registry access when push is required

## Core Command

```bash
# Run from your project directory
skaffold dev
```

When running in dev mode, Skaffold watches source files and automatically rebuilds and redeploys after each code change.

## Dev Loop Workflow

1. Start `skaffold dev` in the project directory.
2. Skaffold watches source files.
3. On change, Skaffold rebuilds the image.
4. Skaffold updates the Kubernetes deployment.
5. You see live status/log feedback and iterate again.

## Example skaffold.yaml

```yaml
apiVersion: skaffold/v4beta6
kind: Config
metadata:
  name: myapp
build:
  artifacts:
    - image: myapp
    docker:
      dockerfile: Dockerfile
deploy:
  kubectl:
    manifests:
      - k8s/*.yaml
```

What this config does:

- `build.artifacts` defines the image to build from the current project
- `deploy.kubectl.manifests` applies Kubernetes manifests from the `k8s` folder
- Skaffold orchestrates build, push, and deploy as one continuous workflow

## Example Skaffold Config (Minimal, as shown in lesson slides)

```yaml
apiVersion: skaffold/v2beta29
kind: Config
build:
  artifacts:
    - image: myapp
      context: .
deploy:
  kubectl:
    manifests:
      - k8s/*
```

What this minimal config highlights:

- defines image build artifacts
- specifies deployment manifest source
- lets Skaffold orchestrate the dev loop directly from configuration

## Typical Commands

```bash
# Start continuous build/deploy/watch loop
skaffold dev

# Optional: enable automatic port-forwarding for local testing
skaffold dev --port-forward
```

## Benefits

- Faster developer feedback cycles
- Less manual toil (fewer repeated kubectl/build commands)
- Works with local and remote Kubernetes clusters
- Consistent workflow for kind and minikube

## Trade-Offs and Considerations

- Repeated image updates may require frequent registry pushes
- Large projects can consume more CPU and memory during rapid rebuilds
- You should still monitor resource use while developing

## CKAD Note

Skaffold is a developer inner-loop tool and is **not** on the CKAD exam — nothing in `skaffold dev`, `skaffold.yaml`, or its builders (Docker/Kaniko/Buildpacks) is tested.

- The exam expects you to build/deploy manually with `kubectl apply -f`, `kubectl set image`, and `kubectl rollout status`/`undo`.
- What Skaffold automates (build → push → deploy → watch) maps to skills you *are* tested on, just performed by hand.
- Treat the `skaffold.yaml` schema (`build.artifacts`, `deploy.kubectl.manifests`) as background, not something to memorize.

## Key Takeaway

Use Skaffold when you want fast, automated Kubernetes development with minimal manual redeploy work and tight feedback loops.
