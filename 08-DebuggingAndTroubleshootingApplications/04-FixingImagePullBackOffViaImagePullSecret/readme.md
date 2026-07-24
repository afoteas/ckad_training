# Fixing ImagePullBackOff via ImagePullSecret

This lesson demonstrates how to create a Docker registry secret and use `imagePullSecrets` in a pod spec.

## Why This Fix Works

Private registries require authentication. Kubernetes reads registry credentials from a secret and uses them during image pull.

## Create Docker Registry Secret

```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<username> \
  --docker-password=<password-or-token> \
  --docker-email=<email>
```

Verify secret:

```bash
kubectl get secrets
```

## Use imagePullSecrets in Pod Spec

```yaml
spec:
  containers:
    - name: app
      image: <private-image>
  imagePullSecrets:
    - name: dockerhub-secret
```

Apply and verify:

```bash
kubectl apply -f pod-with-imagepullsecret.yaml
kubectl get pods
kubectl describe pod <pod-name>
```

## Notes

- never hard-code credentials in workload manifests
- prefer short-lived tokens when supported by registry

## CKAD Tips

- The fast path is imperative: `kubectl create secret docker-registry <name> --docker-server=... --docker-username=... --docker-password=... --docker-email=...`.
- `imagePullSecrets` is a list under `spec:` (a peer of `containers:`); each entry is just `- name: <secret>`.
- Verify the secret exists with `kubectl get secrets` and confirm it is type `kubernetes.io/dockerconfigjson`.
- After applying, re-check with `kubectl get pods` and `kubectl describe pod <pod>` to see the pull succeed.
- For a deployment, patch the pod template's `imagePullSecrets` (not the top-level deployment spec) so new pods inherit the credentials.

## Key Takeaway

Fixing a private-registry `ImagePullBackOff` is a two-step pattern: create a `docker-registry` secret, then reference it under the pod spec's `imagePullSecrets` so the kubelet can authenticate and pull.