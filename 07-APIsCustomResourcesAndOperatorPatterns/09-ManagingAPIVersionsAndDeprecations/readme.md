# Managing API Versions & Deprecations

This lesson covers why Kubernetes API versioning matters and how to migrate manifests before cluster upgrades break them.

## Why Versioning Matters

Kubernetes evolves quickly, and APIs can be deprecated or removed over time. Versioning gives teams a safe migration path instead of forcing emergency changes right before an upgrade.

## API Lifecycle

### Alpha

- experimental
- may change or disappear
- often disabled by default

### Beta

- enabled by default more often
- more stable than alpha
- still subject to change

### Stable

- long-term support target
- strongest backward compatibility guarantees

## Detecting Deprecated APIs

The transcript emphasizes checking instead of guessing.

Common inputs:

- Kubernetes release notes
- API server metrics for deprecated endpoint usage
- manifest scanners such as Kubent or Pluto

Example command to check deprecated API usage metrics from the API server:

```bash
kubectl get --raw /metrics | grep apiserver_requested_deprecated_apis
```

## Migration Strategy

1. Audit existing manifests for deprecated API versions.
2. Update manifests to newer API versions and fields.
3. Test in staging or an upgrade sandbox.
4. Add CI checks that block deprecated APIs from re-entering the repo.

## Conversion Webhooks

For CRDs, conversion webhooks can help serve multiple versions at once.

They allow:

- a stored version under the hood
- client access through a preferred served version
- smoother upgrades across version transitions

## Operational Habits

- track Kubernetes release cadence closely
- document API version dependencies for critical apps
- automate manifest scanning in CI/CD
- train teams on migration practices so upgrades stay routine

## Key Takeaways

- detect deprecations early
- migrate methodically, not reactively
- automate guardrails so deprecated APIs do not return to the codebase