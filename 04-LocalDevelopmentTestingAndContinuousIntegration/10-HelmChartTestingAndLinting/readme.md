# Helm Chart Testing and Linting

This guide explains why Helm chart testing matters and how to combine linting, runtime chart tests, and CI automation to prevent broken releases.

## Why Test Helm Charts

A Helm chart bundles templates, values, and deployment configuration. Small mistakes can break deployments across environments, for example:

- wrong selectors
- missing required values
- template typos
- invalid YAML rendering

Testing and linting catch these issues before release, which improves reliability in CI/CD pipelines.

## Helm Lint: Static Validation Before Deploy

Helm lint analyzes chart structure and template quality before installation.

What it checks:

- chart structure and required metadata
- template rendering and YAML format issues
- common chart best-practice warnings

Common commands:

```bash
helm lint ./mychart
helm lint ./mychart --strict
helm lint ./mychart -f values.yaml
```

Think of linting as a fast quality gate: it validates chart packaging and catches errors early.

## Helm Test: Runtime Validation in a Cluster

Helm test goes beyond static checks. It runs test pods/hooks defined by the chart after installation.

This validates runtime behavior such as:

- application startup
- service resolution and connectivity
- post-install health expectations

Typical commands:

```bash
helm install demo ./mychart
helm test demo --timeout 5m
```

The output clearly reports pass/fail, giving confidence that the chart works in a real cluster, not only in template rendering.

## CT Tool: Scaled Chart Validation for Repos

Chart Testing, usually called CT, automates linting and testing for multiple charts.

Why teams use CT:

- runs lint/test consistently across chart repositories
- integrates into pull request and pipeline checks
- validates compatibility against multiple Kubernetes versions
- helps standardize chart quality at scale

## Recommended Workflow

Use this sequence in local checks and CI pipelines:

1. run helm lint to validate chart structure and templates
2. deploy chart into a test cluster
3. run helm test to execute runtime checks
4. run CT in CI for automated multi-chart validation
5. promote chart only after all checks pass

By chaining these steps, teams ensure charts are structurally correct, functionally verified, and safe to promote between environments.

## Practical Commands

```bash
# 1) Static linting
helm lint ./mychart

# 2) Install to test cluster
helm upgrade --install demo ./mychart --namespace demo --create-namespace

# 3) Runtime chart tests
helm test demo --timeout 5m

# 4) Optional cleanup
helm uninstall demo -n demo
```

## CI/CD Guidance

- run linting on every pull request
- run runtime chart tests in an ephemeral test cluster
- fail the pipeline immediately on lint/test failures
- use CT when managing multiple charts or Kubernetes-version matrices

## Summary

Helm chart quality is best protected by combining:

1. helm lint for fast static validation
2. helm test for runtime verification
3. CT for scalable automation in CI/CD

This approach reduces release risk and prevents broken deployments from reaching production.

## CKAD Note

CKAD covers using Helm to **deploy existing packages**, but chart authoring, `helm lint`, `helm test`, and the Chart Testing (`ct`) tool shown here are beyond exam scope.

- Examinable: `helm install`, `helm upgrade --install`, `helm list`, `helm uninstall`, and overriding values with `--set`/`-f values.yaml`.
- Not examinable: `helm lint --strict`, `helm test`, the `ct` tool, and multi-version chart matrices — these are chart-maintainer/CI concerns.
- If Helm appears on the exam, focus on installing/upgrading a chart and overriding values, not validating or authoring one.

## Key Takeaway

Combining `helm lint`, `helm test`, and `ct` protects chart quality in CI/CD, but for CKAD you only need to install and upgrade existing charts with value overrides — chart testing itself is real-world background.
