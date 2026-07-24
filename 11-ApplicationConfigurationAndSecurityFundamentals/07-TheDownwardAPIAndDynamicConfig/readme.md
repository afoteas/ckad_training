# The Downward API and Dynamic Config

Applications sometimes need awareness of their own runtime identity inside Kubernetes. The Downward API provides that self-awareness without requiring the application to call the Kubernetes API directly.

## What the Downward API Does

The Downward API lets a running Pod consume information about itself, such as:

- Pod name
- namespace
- labels
- annotations
- Pod IP
- resource requests or limits

This data is delivered by Kubernetes directly to the container.

## Why It Matters

The Downward API is useful when an application needs runtime metadata for:

- logging
- metrics tagging
- service identification
- workload self-description
- reading labels or resource assignments

Because the data comes from Kubernetes directly, the application does not need to query the API server or use extra permissions.

## Two Main Consumption Patterns

### Environment variables

Best for simple fields such as:

- `metadata.name`
- `metadata.namespace`

This is easy for applications that only need a few identity values.

Important behavior:

- values are injected at container start
- they do not update dynamically after the container is created

### Mounted volume files

Best for more complex or structured metadata such as:

- labels
- annotations
- resource requests and limits

Kubernetes writes the requested fields into files under a mounted path such as `/etc/podinfo`.

This is a good fit when the application expects to read metadata from the filesystem.

## Common Example

A container might receive:

- `POD_NAME` through an environment variable
- all labels via a file such as `/etc/podinfo/labels`

That allows the workload to enrich logs or dynamically inspect runtime metadata.

## Example: YAML

Manifest file:

- `downwardapi-demo.yaml`

This example injects the Pod name through an environment variable and writes Pod labels to `/etc/podinfo/labels`.

Example usage:

```bash
kubectl apply -f downwardapi-demo.yaml
kubectl get pod downwardapi-demo

# Verify POD_NAME from env var
kubectl exec downwardapi-demo -- printenv POD_NAME

# Verify labels written by Downward API volume
kubectl exec downwardapi-demo -- cat /etc/podinfo/labels

# Cleanup
kubectl delete -f downwardapi-demo.yaml
```

## Best Practices

- Use the Downward API only for non-sensitive self-referential metadata.
- Use ConfigMaps for normal configuration and Secrets for sensitive values.
- Keep mount paths and file names consistent.
- Only inject fields the application really needs.
- Validate how your application parses labels and annotations before production use.

## CKAD Tips

- Env vars use `valueFrom.fieldRef` (e.g. `metadata.name`, `metadata.namespace`, `status.podIP`) and `resourceFieldRef` for CPU/memory requests and limits.
- Labels and annotations can ONLY be exposed through a `downwardAPI` volume — not as environment variables.
- Volume-mounted fields update when labels/annotations change; env-var fields are fixed at container start.
- Verify quickly with `kubectl exec <pod> -- printenv POD_NAME` and `kubectl exec <pod> -- cat /etc/podinfo/labels`.
- No ServiceAccount token or RBAC is needed — the kubelet injects the data, so it never touches the API server.

## Key Takeaway

The Downward API gives Kubernetes workloads built-in self-awareness. It is a simple and powerful way to expose Pod metadata and resource information to applications without extra API permissions.
