# ConfigMap and Environment Variable Management

Handling configuration externally from application code is a core cloud-native pattern and aligns with the Twelve-Factor App methodology. In Kubernetes, the primary resource for non-sensitive configuration is the ConfigMap.

## Why ConfigMaps Matter

ConfigMaps allow the same container image to move through development, staging, and production while environment-specific settings are injected at runtime. This keeps images portable and avoids hard-coding configuration into the application.

A single ConfigMap can be shared by multiple Pods and Deployments, which helps keep related services consistent across a microservice platform.

## What a ConfigMap Stores

A ConfigMap stores data as key-value pairs.

Common examples:

- API gateway URLs
- feature flags
- application mode
- port numbers
- logging levels
- configuration file contents

## Two Main Consumption Patterns

### Environment variables

This is the simplest pattern and is commonly used by stateless applications. Individual keys from the ConfigMap are mapped into container environment variables.

Benefits:

- easy for application code to consume
- standard Twelve-Factor pattern
- good for simple scalar values

Typical use cases:

- `APP_MODE`
- `APP_PORT`
- `LOG_LEVEL`

### Mounted files

This pattern is better when the application expects configuration files on disk. Each key becomes a file name and the corresponding value becomes the file content.

Benefits:

- ideal for structured formats like `.ini`, `.json`, `.xml`, or `.properties`
- useful for large multiline configuration blocks
- avoids forcing complex config into environment variables

## Creating ConfigMaps

ConfigMaps can be created in several ways:

- define them directly in YAML and apply with `kubectl apply -f`
- create quick one-off ConfigMaps with `kubectl create configmap`
- load larger config files with `kubectl create configmap --from-file`

After creation, validate them with commands such as:

- `kubectl get configmap <name>`
- `kubectl describe configmap <name>`

## Update Behavior

ConfigMaps support update-driven workflows:

- environment variable values are injected at container start
- mounted ConfigMap volumes are refreshed automatically by Kubernetes after the ConfigMap changes

Mounted-file refresh is not instantaneous, but it is usually observed within about a minute.

## Example Shape

A simple ConfigMap typically contains straightforward key-value data such as:

- `APP_MODE=production`
- `APP_PORT=8080`

Those keys can then be consumed either as environment variables or as mounted files.

## Best Practices

- Never put secrets, passwords, tokens, or API keys into ConfigMaps.
- Use clear naming conventions tied to the consuming application.
- Keep the ConfigMap in the same namespace as the consuming Pods.
- Add labels or annotations for traceability and versioning.
- Manage ConfigMap changes through the same GitOps or review workflow used for application changes.
- Use RBAC to limit who can read or modify ConfigMaps.

## Key Takeaway

ConfigMaps provide flexible, reusable, non-sensitive configuration management for Kubernetes workloads. They are one of the main tools that make container images portable and environment-agnostic.