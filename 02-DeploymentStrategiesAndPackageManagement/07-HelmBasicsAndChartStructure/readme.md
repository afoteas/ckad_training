# Helm Basics and Chart Structure

## What Helm is
Helm is the package manager for Kubernetes.
It helps you:
- Package Kubernetes manifests as reusable charts.
- Parameterize deployments with values.
- Install, upgrade, rollback, and uninstall releases consistently.

## Core terms
- Chart: A package of Kubernetes resources and templates.
- Release: One installed instance of a chart in a cluster.
- Repository: A place to publish and pull charts.
- Values: Configuration inputs used by templates.
- Template: Manifest files rendered with values before apply.

## Standard chart structure
```text
mychart/
  Chart.yaml
  values.yaml
  charts/
  templates/
    deployment.yaml
    service.yaml
    _helpers.tpl
  .helmignore
```

What each part does:
- Chart.yaml: Chart metadata (name, version, appVersion).
- values.yaml: Default configuration values.
- templates/: Kubernetes manifest templates.
- templates/_helpers.tpl: Reusable template helpers.
- charts/: Dependency charts.
- .helmignore: Files to exclude from packaging.

## Most important commands
```bash
helm create mychart
helm lint mychart
helm template myrelease mychart
helm install myrelease mychart -n myns --create-namespace
helm upgrade myrelease mychart -n myns
helm upgrade --install myrelease mychart -n myns
helm rollback myrelease 1 -n myns
helm uninstall myrelease -n myns
helm list -A
helm history myrelease -n myns
```

## Values and override order
Typical precedence (lowest to highest):
1. Chart defaults in values.yaml
2. Parent chart values (for subcharts)
3. Extra values files with -f
4. Inline values with --set

Example:
```bash
helm upgrade --install web ./mychart -f values-prod.yaml --set image.tag=1.2.3
```

## Templating basics
Common objects:
- .Values: User and chart values.
- .Release.Name: Release name.
- .Chart.Name: Chart name.

Example snippet:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
```

Useful functions:
- default
- quote
- toYaml
- nindent
- include
- required

## Dependencies
Define dependencies in Chart.yaml, then fetch/build:
```yaml
dependencies:
  - name: redis
    version: 19.x.x
    repository: https://charts.bitnami.com/bitnami
```

```bash
helm dependency update
```

## Safe rollout workflow
1. Render first and inspect output.
2. Lint chart.
3. Dry-run install or upgrade.
4. Apply for real, then verify.

```bash
helm template myrelease ./mychart -f values.yaml
helm lint ./mychart
helm upgrade --install myrelease ./mychart -n myns --dry-run --debug
kubectl get all -n myns
helm status myrelease -n myns
```

## CKAD-focused tips
- Know chart vs release clearly.
- Practice helm template and helm upgrade --install.
- Be comfortable overriding values with files and --set.
- Use rollback quickly after a failed upgrade.
- Verify resources with kubectl and release state with helm status and helm history.

## Quick troubleshooting
- Template error: Run helm template or helm upgrade --dry-run --debug.
- Values not applied: Check merged values with helm get values.
- Bad rollout: Use helm history then helm rollback.

## Transcript Enhancements (Preserved Notes Kept)

### Helm Workflow Lifecycle

1. create or fetch chart
2. customize values
3. install as release
4. upgrade over time
5. rollback if release is unhealthy

### Key Structural Components

- `Chart.yaml` for chart metadata and dependencies
- `values.yaml` for default configurable parameters
- `templates/` for Go-template manifests
- `charts/` for subcharts

### Operational Value

Helm provides repeatable packaging, versioned releases, and native rollback history, making multi-environment Kubernetes operations easier to standardize.
