# Secret Management

Kubernetes Secrets are the standard resource for handling sensitive configuration such as credentials, tokens, keys, and certificates.

## Why Secrets Exist

Treating sensitive values like normal configuration is a security risk. Secrets provide a dedicated mechanism for distributing confidential data to workloads with greater care than ConfigMaps.

Examples of sensitive data:

- database passwords
- API keys
- OAuth tokens
- SSH keys
- TLS certificates
- private registry credentials

## How Secrets Are Stored

Secrets are stored in the cluster's etcd database. In manifests, the values are base64-encoded, but base64 is not encryption.

When a Pod consumes a Secret, Kubernetes makes the data available either:

- in memory through environment variables
- as files in a temporary mounted volume
- through built-in resource references such as image pull credentials

## Common Secret Types

### Opaque

The default type for arbitrary user-defined sensitive data.

### ServiceAccount token

Used by Pods to authenticate to the Kubernetes API when running under a ServiceAccount.

### `kubernetes.io/dockerconfigjson`

Stores credentials for pulling images from private registries.

### `kubernetes.io/tls`

Stores a TLS certificate and private key, commonly for ingress HTTPS termination.

## Ways Applications Consume Secrets

### Mounted files

This is generally the preferred method. Secret values are exposed as read-only files in a temporary volume.

Why it is preferred:

- keeps sensitive data out of command lines and process lists
- fits applications that read credentials from files
- reduces accidental exposure in logs

### Environment variables

This works similarly to ConfigMaps, but it is less secure because environment variables are more easily exposed.

Use this carefully, especially for highly sensitive values.

### Direct component usage

Some Kubernetes components consume Secrets directly. A common example is `imagePullSecrets` for authenticating to a private container registry.

## Secret Manifest Basics

A typical Secret:

- uses `kind: Secret`
- often uses `type: Opaque`
- stores values under the `data` section
- requires those values to be base64-encoded before submission

Kubernetes automatically decodes them when the Pod consumes the Secret.

## Best Practices

- Never store sensitive values in ConfigMaps.
- Never hard-code secrets into container images.
- Never commit plaintext secrets into source control.
- Use RBAC to restrict who can read or update Secrets.
- Rotate secrets regularly.
- Review which workloads consume which secrets.
- Remove unused or stale secrets.
- Enable encryption at rest for stronger protection in etcd.

## Key Takeaway

Secrets are a critical part of Kubernetes security. They provide the standard mechanism for safely distributing confidential values to running workloads while supporting least-privilege access and operational control.