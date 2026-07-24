# ImagePull Errors & Registry Auth

This lesson focuses on `ImagePullBackOff`: why it happens, how to diagnose it quickly, and how to prevent repeat failures.

## What ImagePullBackOff Means

Kubernetes could not pull the container image needed to start the container.

## Common Causes

- invalid image name or tag
- private registry credentials missing or incorrect
- registry rate limits
- network/DNS/proxy/firewall path issues to registry

## Diagnose with kubectl

```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
kubectl logs <pod-name> --previous
```

Use `describe` and events to confirm pull/authentication failure reason text.

## Registry Authentication with Secrets

1. Create a Docker registry secret:

```bash
kubectl create secret docker-registry dockerhub-secret \
	--docker-server=https://index.docker.io/v1/ \
	--docker-username=<username> \
	--docker-password=<password-or-token> \
	--docker-email=<email>
```

2. Reference the secret in pod spec under `imagePullSecrets`:

```yaml
spec:
	containers:
		- name: app
			image: <private-image>
	imagePullSecrets:
		- name: dockerhub-secret
```

3. Kubernetes uses these credentials to authenticate and pull the image from the registry.

## Prevention Practices

- use explicit tags instead of `latest`
- monitor pull quotas and rate limits
- store credentials in Kubernetes secrets, not plain manifests
- validate registry connectivity from cluster nodes
- pre-pull critical images when appropriate

## CKAD Tips

- Create registry credentials imperatively: `kubectl create secret docker-registry <name> --docker-server=... --docker-username=... --docker-password=...` — memorize the flag names, they're easy to fumble under time pressure.
- Reference the secret via `imagePullSecrets` at the pod `spec` level (a sibling of `containers`), not inside a container.
- Confirm the failure reason with `kubectl describe pod <pod>` and `kubectl get events --sort-by='.lastTimestamp'`; the message text distinguishes a bad tag from an auth failure.
- `kubectl logs <pod> --previous` helps only after the container has started — an image that never pulls produces no logs, so rely on `describe`/events instead.
- Prefer explicit image tags over `latest` so retries pull a deterministic image.

## Key Takeaway

`ImagePullBackOff` means the kubelet cannot fetch the image; diagnose via `describe`/events and fix the root cause — corrected image/tag, or a `docker-registry` secret wired in through `imagePullSecrets`.