# SecurityContexts and Pod Security Standards

Securing Kubernetes workloads is not only about network policy and secrets. It also requires controlling what container processes are allowed to do on the host. That is the role of `securityContext`.

## What a SecurityContext Does

A SecurityContext defines privilege and access settings for a Pod or container.

It can control:

- which user ID the process runs as
- which group ID owns mounted volumes
- whether privilege escalation is allowed
- whether the root filesystem is read-only
- which Linux capabilities are granted or dropped

These controls reduce the blast radius of a compromised container.

## Pod-Level vs Container-Level

Security settings can be applied at two levels.

### Pod level

These settings establish a baseline for all containers in the Pod.

Common examples:

- `fsGroup`
- `supplementalGroups`
- shared defaults for the workload

### Container level

These settings apply to one specific container and can override or tighten the pod-level defaults.

Common examples:

- `runAsUser`
- `allowPrivilegeEscalation`
- `readOnlyRootFilesystem`
- `capabilities`

## Common Security Controls

### Run as non-root

Avoid running containers as root unless absolutely necessary.

### Disable privilege escalation

Set `allowPrivilegeEscalation: false` to prevent the process from gaining more privileges than intended.

### Read-only root filesystem

Set `readOnlyRootFilesystem: true` to make it harder for an attacker to write malicious files into the container image filesystem.

### Drop unnecessary capabilities

Linux capabilities split root privileges into smaller pieces. Only grant the ones the application truly needs.

## Example: SecurityContext YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
	name: secure-pod
spec:
	securityContext:
		runAsUser: 1000
		fsGroup: 2000
	containers:
		- name: app
			image: nginx
			securityContext:
				allowPrivilegeEscalation: false
				readOnlyRootFilesystem: true
```

This example combines pod-level defaults (`runAsUser`, `fsGroup`) with container-level hardening (`allowPrivilegeEscalation`, `readOnlyRootFilesystem`).

## Pod Security Standards (PSS)

Pod Security Standards define three security policy levels for namespaces.

### Privileged

Least restrictive. Intended mainly for system-level workloads that need broad host access.

### Baseline

A practical default for many workloads. It blocks common unsafe settings while allowing standard application behavior.

### Restricted

Most secure and prescriptive. Enforces strong least-privilege defaults and is ideal for highly security-sensitive workloads.

## Best Practices

- Always prefer non-root execution.
- Set `allowPrivilegeEscalation: false` when possible.
- Use `readOnlyRootFilesystem: true` where the app allows it.
- Drop unneeded Linux capabilities.
- Enforce Pod Security Standards at the namespace level.
- Scan manifests for violations before deployment.
- Treat exceptions as explicit, reviewed decisions.

## CKAD Tips

- Set pod-level fields (`runAsUser`, `runAsNonRoot`, `fsGroup`) and/or container-level fields (`allowPrivilegeEscalation`, `readOnlyRootFilesystem`, `capabilities`); container level overrides pod level.
- Drop everything then add back what's needed: `capabilities.drop: ["ALL"]` with a minimal `capabilities.add`.
- With `readOnlyRootFilesystem: true`, mount an `emptyDir` for any path the app must write to.
- Verify identity at runtime with `kubectl exec <pod> -- id` / `whoami` to confirm the UID and non-root.
- Enforce Pod Security Standards per namespace via labels, e.g. `pod-security.kubernetes.io/enforce=restricted`.
- A root image under `runAsNonRoot`/`restricted` fails to start — watch for `CreateContainerConfigError`.

## Key Takeaway

SecurityContexts are one of the main workload-level security controls in Kubernetes. Combined with Pod Security Standards, they help enforce least privilege and support a stronger zero-trust posture for running applications.
