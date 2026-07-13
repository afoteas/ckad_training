# Tilt for Local Microservice Stacks

This guide demonstrates how to use Tilt to orchestrate and develop multiple microservices locally.

## Overview

Tilt is a toolkit for local development of microservices. It manages multi-service deployments, handles rebuilding, and provides a unified UI for monitoring your entire stack.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
```

## Basic Tiltfile Structure

Create a `Tiltfile` in your project root:

```python
# Load all services
load('ext://restart_process', 'docker_build_with_restart')

docker_build('my-service-1', '.', dockerfile='service1/Dockerfile')
docker_build('my-service-2', '.', dockerfile='service2/Dockerfile')

# Deploy resources
k8s_yaml('k8s/deployment.yaml')

# Forward ports
k8s_resource('my-service-1', port_forwards=8001)
k8s_resource('my-service-2', port_forwards=8002)
```

## Starting Tilt

```bash
# Launch Tilt UI
tilt up

# View logs for specific service
tilt logs my-service

# Restart service
tilt trigger my-service
```

## Advanced Configuration

### Service Dependencies

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
