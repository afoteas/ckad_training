# Configuring Skaffold Hot-Reload with Kaniko Build

This guide shows how to set up Skaffold with Kaniko for in-cluster image builds and file sync for fast iterative development.

## Overview

Kaniko builds container images inside Kubernetes clusters without requiring Docker daemon access. Combined with file sync, this enables near-instant feedback for code changes.

## Kaniko Benefits

- Build images in Kubernetes pods
- No Docker daemon required
- Supports privileged and unprivileged containers
- Works in CI/CD environments

## Skaffold Configuration with Kaniko

```yaml
apiVersion: skaffold/v4beta6
kind: Config
metadata:
  name: my-app
build:
  artifacts:
  - image: my-app
    kaniko:
      dockerfile: Dockerfile
      buildContext:
        local:
          push: false  # For local clusters like kind/minikube
deploy:
  kubectl: {}
```

## File Sync for Hot-Reload

```yaml
build:
  artifacts:
  - image: my-app
    docker:
      dockerfile: Dockerfile
    sync:
      manual:
      - src: "src/**/*.js"
        dest: /app/src
      - src: "config/**/*.yaml"
        dest: /app/config
```

## Profiles for Local vs CI

```yaml
profiles:
- name: local
  activation:
  - command: dev
  build:
    artifacts:
    - image: my-app
      sync:
        manual:
        - src: "**/*.js"
          dest: /app
- name: ci
  build:
    artifacts:
    - image: my-app
      kaniko: {}
```

## Usage

```bash
# Run with local profile (includes file sync)
skaffold dev -p local

# Run with CI profile (full Kaniko build)
skaffold dev -p ci
```

## Supported File Sync

- JavaScript/TypeScript (node_modules synced)
- Python (pip packages handled)
- Compiled languages (requires careful setup)
- Configuration files (always synced)

## Best Practices

1. Use file sync for interpreted languages
2. Test file sync thoroughly before relying on it
3. Fall back to full rebuild if sync issues occur
4. Monitor container logs during development
