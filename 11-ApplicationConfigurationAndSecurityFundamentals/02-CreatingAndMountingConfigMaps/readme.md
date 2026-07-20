# Creating and Mounting ConfigMaps

This lesson demonstrates two common ways to inject ConfigMap data into a Pod:

1. as environment variables
2. as mounted files

Both methods allow configuration to stay outside the container image.

## Goal

Create a ConfigMap with both simple key-value settings and multiline file content, then consume that data from a Deployment.

## Method A: Environment Variable Injection

This method maps a specific ConfigMap key into a container environment variable.

Typical use cases:

- log levels
- feature flags
- port numbers
- runtime mode values

Example idea:

- ConfigMap key: `log_level`
- environment variable in the Pod: `APP_LOG_LEVEL`

The application simply reads the value from its environment.

## Method B: Mounted File Injection

This method mounts the ConfigMap as a volume. Each key in the ConfigMap becomes a file in the mounted directory.

Typical use cases:

- `.properties` files
- `.ini` files
- multiline app configuration
- frameworks that expect config files from disk

Example idea:

- ConfigMap key: `app_config.properties`
- mounted file path inside the container: something like `/etc/config/app_config.properties`

## Demo Flow

### 1. Create the ConfigMap

The ConfigMap contains:

- a simple key-value setting such as `log_level: INFO`
- a multiline configuration file such as `app_config.properties`

Files in this lesson:

- `my-configmap.yaml`
- `app-configmap-deployment.yaml`

Deploy it and confirm its contents:

```bash
kubectl apply -f my-configmap.yaml
kubectl describe configmap app-settings
```

### 2. Create the Deployment

The Deployment consumes the same ConfigMap in two ways:

- one key is exposed as an environment variable
- the multiline configuration is mounted as a volume

Important detail:

- the Deployment must reference the ConfigMap by its exact name
- the volume definition and volume mount name must match

Deploy it:

```bash
kubectl apply -f app-configmap-deployment.yaml
kubectl get pods -l app=config-demo
```

### 3. Verify the Result

A simple container can print:

- the environment variable value from Method A
- the mounted file contents from Method B

This confirms that both injection strategies work correctly.

Example verification flow:

```bash
POD=$(kubectl get pods -l app=config-demo -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD"

# Alternative: fetch logs from all pods matching the app label
kubectl logs -l app=config-demo --all-containers=true --max-log-requests=20 --tail=-1
```

Option breakdown for the command above:

- `-l app=config-demo`: selects all Pods with label `app=config-demo`
- `--all-containers=true`: includes logs from every container in each selected Pod
- `--max-log-requests=20`: caps concurrent log streams when multiple Pods match
- `--tail=-1`: returns full available logs instead of truncating to recent lines

If you want live streaming, add `-f`:

```bash
kubectl logs -f -l app=config-demo --all-containers=true --max-log-requests=20 --tail=-1
```

## What This Proves

The same ConfigMap can hold multiple kinds of configuration and be consumed using different patterns inside the same workload.

That makes ConfigMaps very practical for real applications where some values are simple toggles and others are full configuration files.

## Best Practices

- Use environment variables for small scalar values.
- Use mounted files for structured or multiline configuration.
- Keep non-sensitive config in ConfigMaps only.
- Validate mounted file paths carefully.
- Ensure the referenced ConfigMap name matches exactly.

## Cleanup

```bash
kubectl delete -f app-configmap-deployment.yaml
kubectl delete -f my-configmap.yaml
```