# Live Coding with Skaffold Dev Loop

This guide demonstrates how to use Skaffold for rapid, iterative development with automatic build and deploy cycles.

## Overview

Skaffold automates the workflow of building, pushing, and deploying your application whenever you save code changes. This enables a true "code → save → test" loop.

## Installation

```bash
# Download and install Skaffold
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x skaffold
sudo mv skaffold /usr/local/bin/
```

## Initialize Skaffold

```bash
# Create a skaffold.yaml configuration
skaffold init

# Or create manually in your project root
touch skaffold.yaml
```

## Basic Configuration

```yaml
apiVersion: skaffold/v4beta6
kind: Config
metadata:
  name: my-app
build:
  artifacts:
  - image: my-app
    docker:
      dockerfile: Dockerfile
deploy:
  kubectl: {}
```

## Run Dev Loop

```bash
# Start continuous build/deploy/log
skaffold dev

# With file-sync and specific port forwarding
skaffold dev --port-forward
```

## Dev Loop Workflow

1. Skaffold watches your local files
2. On save, automatically rebuilds container image
3. Deploys updated image to cluster
4. Streams logs to your terminal
5. Ready for next iteration

## Benefits

- Instant feedback on code changes
- No manual kubectl apply commands
- Automatic image rebuilds
- Live container logs in terminal
- Perfect for rapid prototyping
