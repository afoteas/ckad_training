# Helm Chart Testing and Linting

This guide covers best practices for testing and linting Helm charts to ensure quality and correctness.

## Overview

Helm chart linting and testing help catch configuration errors early and ensure charts work correctly across different environments.

## Helm Lint

Performs static analysis on your Helm chart:

```bash
# Lint a chart
helm lint ./mychart

# Lint with strict mode
helm lint ./mychart --strict

# Lint specific values
helm lint ./mychart -f values.yaml
```

## Common Lint Issues

- Missing required fields
- Invalid YAML syntax
- Deprecated Kubernetes API versions
- Image pull policy issues
- Resource quotas and limits

## Template Testing

### Dry Run
```bash
# See rendered manifests without installing
helm install my-release ./mychart --dry-run --debug

# With custom values
helm install my-release ./mychart --dry-run --debug -f custom-values.yaml
```

### Template Rendering
```bash
# Render templates locally
helm template my-release ./mychart

# Render with values
helm template my-release ./mychart -f values-prod.yaml
```

## Chart Testing with Helm Test

```yaml
# templates/tests/test-connection.yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "mychart.fullname" . }}-test-connection"
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "mychart.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

### Run Chart Tests
```bash
# Test the chart
helm test my-release

# With timeout
helm test my-release --timeout 5m
```

## Validation

```bash
# Validate chart structure
helm chart pull oci://example.com/mychart
helm chart inspect oci://example.com/mychart

# Check Chart.yaml integrity
helm lint --validate-maintainers ./mychart
```

## Testing Different Scenarios

```bash
# Test with minimal values
helm template . -f minimal-values.yaml | kubectl apply -f - --dry-run=client

# Test with production values
helm template . -f production-values.yaml | kubectl apply -f - --dry-run=client

# Test with multiple value files
helm template . -f values.yaml -f values-prod.yaml
```

## CI/CD Integration

```yaml
# GitLab CI example
helm-lint:
  stage: test
  script:
    - helm lint ./mychart
    - helm lint ./mychart -f values-dev.yaml
    - helm lint ./mychart -f values-prod.yaml

helm-test:
  stage: test
  script:
    - helm install test ./mychart
    - helm test test
    - helm uninstall test
```

## Best Practices

1. **Lint early**: Run helm lint in pre-commit hooks
2. **Test values**: Test with different value combinations
3. **API versions**: Use stable API versions, avoid alpha/beta
4. **Documentation**: Document all values in values.yaml
5. **Semantic versioning**: Follow semver for chart versions
6. **Dry-run validation**: Always use --dry-run before install

## Useful Tools

- `helm-docs`: Generate documentation from values.yaml
- `ct` (Chart Testing): Comprehensive chart testing tool
- `kubeval`: Validate Kubernetes manifests
- `helm-lint`: Built-in linting
