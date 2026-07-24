# Performing Multi-Service Dev with Tilt and Live Updates

This guide demonstrates advanced Tilt techniques for efficient multi-service development with live updates.

## Overview

Live updates in Tilt allow you to sync code changes directly into running containers without rebuilding images, dramatically speeding up development cycles.

## Live Update Configuration

```python
docker_build(
  'my-service',
  '.',
  dockerfile='Dockerfile',
  only=['src/', 'requirements.txt'],
  live_update=[
    sync('./src', '/app/src'),
    run('pip install -r requirements.txt', trigger=['requirements.txt']),
  ]
)
```

## Fall Back to Full Rebuild

```python
docker_build(
  'my-service',
  '.',
  dockerfile='Dockerfile',
  live_update=[
    sync('./src', '/app/src'),
    run('./restart.sh', trigger=['package.json']),
  ],
  entrypoint=['sh', '-c', 'while true; do python app.py; done'],
)
```

## Grouping Services

```python
# Group services by stack
services = ['web', 'api', 'worker', 'cache', 'db']

for service in services:
  docker_build(
    service,
    f'./{service}',
    dockerfile=f'{service}/Dockerfile',
  )
  k8s_yaml(f'k8s/{service}.yaml')
```

## Resource Dependencies

```python
# Define startup order and dependencies
k8s_resource('postgres', labels=['database'])
k8s_resource('redis', labels=['cache'], resource_deps=['postgres'])
k8s_resource('api', labels=['services'], resource_deps=['postgres', 'redis'])
k8s_resource('web', labels=['frontend'], resource_deps=['api'])
```

## Selective Service Updates

```python
# Only start specific services
tilt up web api  # Only web and api

# Restart one service
tilt trigger api

# View logs for specific service
tilt logs api
```

## Advanced Sync Rules

### Node.js Example
```python
live_update=[
  sync('./src', '/app/src'),
  run('npm install', trigger=['package.json']),
  run('npm run build', trigger=['src/**/*.ts']),
]
```

### Python Example
```python
live_update=[
  sync('./app', '/app/app'),
  sync('./requirements.txt', '/app/requirements.txt'),
  run('pip install -r requirements.txt', trigger=['requirements.txt']),
]
```

## Performance Tips

1. Exclude unnecessary files with `only[]`
2. Use sync for code-only changes
3. Trigger full rebuild for dependency changes
4. Monitor file watch activity
5. Use Tilt's profiling to optimize builds

## Monitoring Live Updates

```bash
# Enable verbose logging
tilt up --debug

# Check which services are live
tilt status

# Inspect a specific resource
tilt describe my-service
```

## CKAD Note

Tilt live updates (`sync`, `run` triggers, `live_update`, selective `tilt up`/`tilt trigger`) are advanced local-dev tooling and are **out of scope** for CKAD.

- None of the `docker_build`/`live_update` Starlark configuration is tested.
- The transferable idea is startup ordering and dependencies (`resource_deps`), which on the exam you express through readiness probes, init containers, and correct Service wiring.
- Debug workloads on the exam with `kubectl logs`, `kubectl describe`, and `kubectl exec` — not `tilt logs`/`tilt status`.

## Key Takeaway

Tilt live updates sync code straight into running containers to skip image rebuilds for fast multi-service iteration, but this is a developer-experience optimization with no CKAD exam relevance.
