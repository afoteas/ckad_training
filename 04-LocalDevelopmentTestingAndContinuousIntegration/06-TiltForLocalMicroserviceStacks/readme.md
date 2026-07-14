# Tilt for Local Microservice Stacks

This guide explains how Tilt helps manage local Kubernetes development when you move from one service to many microservices.

## Why Microservice Local Dev Gets Hard

As service count grows (APIs, frontends, workers), traditional workflows become painful:

- repeated manual rebuild and redeploy per service
- slow feedback loops
- poor visibility into what is running or broken
- fragmented logs across multiple terminals

Tilt is designed to solve this by unifying build, deploy, and monitoring.

## What Tilt Is

Tilt is an open-source tool for local Kubernetes development, especially useful for multi-service apps.

It uses a `Tiltfile` written in Starlark (Python-like syntax) to define:

- how images are built
- which Kubernetes manifests are deployed
- how services are exposed locally

Tilt provides both:

- CLI workflow
- Web UI with live logs, status, and update visibility

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

## Core Workflow

```bash
tilt up
```

What happens during `tilt up`:

1. Tilt loads the `Tiltfile`
2. Builds images
3. Applies Kubernetes manifests
4. Starts watching source changes
5. Streams logs/status in CLI and UI

## Basic Tiltfile Example (from lesson)

Create a `Tiltfile` in your project root:

```python
# Load Kubernetes manifests
k8s_yaml('k8s/deployment.yaml')

# Build image from current directory
docker_build('myapp', '.')

# Expose app locally via port-forward
k8s_resource('myapp', port_forwards=8000)
```

How this works:

- `k8s_yaml` tells Tilt which manifests to deploy
- `docker_build` defines image build instructions
- `k8s_resource` configures runtime behavior like local port access

## Live Update and Feedback

Tilt watches for source changes.

On file change, Tilt can sync updates directly into running containers (depending on configuration), which avoids full rebuilds for many edits and speeds iteration.

The Tilt UI gives immediate visibility:

- resource health/state
- logs by service
- build/deploy updates in real time
- quick error detection

## Useful Commands

```bash
tilt up

# View resource logs
tilt logs

# Manually trigger a resource update
tilt trigger myapp
```

## Benefits

- Faster microservice feedback loops
- Unified local management for multi-service stacks
- Better visibility with integrated UI and logs
- Reduced manual rebuild/redeploy toil

## Considerations

- Starlark (`Tiltfile`) has a learning curve
- Large service stacks can be resource intensive locally
- You may need a stronger workstation for bigger microservice environments

## Practical Guidance

1. Start with a minimal `Tiltfile` and one service.
2. Add more services incrementally.
3. Use the UI to track failures quickly.
4. Watch CPU/RAM usage as stack size increases.

## Key Takeaway

Tilt is a strong choice for local Kubernetes microservice development because it centralizes build, deploy, and monitoring into one fast feedback workflow.

```python
# Define load order
k8s_resource('database', labels=['infra'])
k8s_resource('api', labels=['app'], resource_deps=['database'])
k8s_resource('web', labels=['app'], resource_deps=['api'])
```

### Custom Build Steps

```python
custom_build(
  'my-service',
  'make build-image',
  only=['./src', './Makefile'],
  tag='dev',
)
```

## Key Features

- **Multi-service dashboard**: View all services in one place
- **Selective rebuilds**: Only rebuild affected services
- **Resource streaming**: See logs from all services
- **Hot reload**: Automatic rebuilds on file changes
- **Error tracking**: Highlight build/deploy issues

## Workflow Tips

1. Group related services with labels
2. Set explicit resource dependencies
3. Use Tilt UI to trigger manual rebuilds
4. Monitor resource usage in dashboard
5. Enable specific services for focused work
