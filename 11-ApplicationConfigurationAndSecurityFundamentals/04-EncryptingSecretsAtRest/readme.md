# Encrypting Secrets at Rest

By default, Kubernetes stores Secret objects in etcd in base64 form, which is reversible and not real encryption. Encrypting Secrets at rest protects them even if someone gains read access to the etcd data store.

## The Problem

Without encryption at rest:

- Secrets are stored in etcd in a form that looks encoded but is easy to reverse.
- Anyone with access to etcd data can potentially recover sensitive values.

## The Solution

Kubernetes supports an encryption configuration file that the API server reads when writing resources to etcd.

A common provider is:

- `aescbc`

With this setup, the API server encrypts Secret data before storing it in etcd.

## Encryption Configuration Overview

An encryption configuration file typically defines:

- the target resource type, such as `secrets`
- one or more encryption providers
- one or more named encryption keys

The API server must be configured to reference this file, then restarted so the new policy is loaded.

## What Changes After Encryption Is Enabled

Secret manifests still look familiar when you apply them with `kubectl`. The major difference is what happens inside etcd:

- before: value is only base64-encoded
- after: value is encrypted before being stored

This means that simply reversing base64 is no longer enough to recover the stored data.

## Important Operational Step

Enabling encryption at rest does not automatically re-encrypt old Secrets already stored in etcd.

Existing Secrets should be rewritten so the API server stores them again using the active encryption policy.

That is why teams often re-apply or replace existing Secret objects after enabling encryption.

## Demo Flow

Files in this lesson:

- `encryption-config.yaml`
- `test-secret.yaml`

1. Create the encryption configuration file in `encryption-config.yaml`.
2. Configure the API server to use it.
3. Restart the API server.
4. Create or update Secrets with `test-secret.yaml`.
5. Re-write older Secrets so they are stored under the new encryption policy.

Example Secret commands:

```bash
kubectl apply -f test-secret.yaml
kubectl get secrets
kubectl get secret test-encryption-secret
```

To re-write existing Secrets after encryption is enabled:

```bash
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
```

Note: actually wiring `encryption-config.yaml` into the API server requires cluster-admin access to the control plane and is often environment-specific. This lesson focuses on the configuration pattern and the secret re-write flow.

## Best Practices

- Treat the encryption provider keys themselves as highly sensitive.
- Keep key material outside source control.
- Use strong rotation procedures for encryption keys.
- Re-encrypt existing Secrets after enabling the feature.
- Pair encryption at rest with RBAC and namespace isolation.
- Remember that base64 is not security.

## Key Takeaway

Encryption at rest protects Secret data inside etcd and closes a major control-plane security gap. It does not replace RBAC, secret rotation, or careful operational handling, but it is an important foundational safeguard.