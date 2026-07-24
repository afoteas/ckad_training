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

### Using `encryption-config.yaml` with the API server

On kubeadm-based control planes, a common pattern is:

1. Copy `encryption-config.yaml` to a control-plane path, for example:

```bash
sudo cp encryption-config.yaml /etc/kubernetes/encryption-config.yaml
sudo chmod 600 /etc/kubernetes/encryption-config.yaml
```

2. Edit the API server static Pod manifest (`/etc/kubernetes/manifests/kube-apiserver.yaml`) and add:

```yaml
- --encryption-provider-config=/etc/kubernetes/encryption-config.yaml
```

3. Ensure the file is mounted into the API server container (hostPath + volumeMount) in the same manifest.

4. Save the manifest and wait for kubelet to restart the API server static Pod.

5. Verify the flag is active:

```bash
kubectl -n kube-system get pod -l component=kube-apiserver -o yaml | grep encryption-provider-config
```

If your environment is managed (EKS/GKE/AKS), this is provider-controlled and usually configured via platform settings, not direct manifest edits.

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

## CKAD Note

- Configuring encryption at rest is a **cluster-admin / CKA** task: it requires an `EncryptionConfiguration` file, editing the `kube-apiserver` static Pod manifest, and control-plane access — all outside CKAD exam scope.
- For CKAD, focus on the in-scope adjacent skills: creating and consuming Secrets (see `03-SecretManagement`) and restricting access to them with RBAC.
- Know conceptually that base64 in a Secret manifest is not encryption and that an etcd provider like `aescbc` encrypts data at rest — but you won't wire up `--encryption-provider-config` on the exam.
- The re-write trick `kubectl get secrets --all-namespaces -o json | kubectl replace -f -` is useful real-world knowledge, not a CKAD objective.

## Key Takeaway

Encryption at rest protects Secret data inside etcd and closes a major control-plane security gap. It does not replace RBAC, secret rotation, or careful operational handling, but it is an important foundational safeguard.
