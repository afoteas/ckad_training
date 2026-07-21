# Seccomp and AppArmor Profiles

Now that Pod Security Admission controls what Pods can do at the API level, this lesson covers **kernel-level isolation** — restricting what containers can do on the shared Linux kernel.

## Why Kernel Isolation Matters

Containers share the **same kernel** as the host. Without restrictions, a container can call any **system call (syscall)** — the interface processes use to ask the kernel to open files, connect to networks, manage memory, and more.

If a container is compromised, an attacker could exploit the kernel to gain host access.

| Without profiles | With profiles |
|------------------|---------------|
| Containers can use any syscall | Only required syscalls are allowed |
| Large attack surface | Reduced attack surface |
| Higher privilege escalation risk | Least-privilege runtime security |

Profiles enforce **least privilege** for Pods — the same principle you apply to users and cloud IAM, but at the container runtime level.

## seccomp (Secure Computing Mode)

**seccomp** is a Linux kernel feature that defines a list of **allowed or denied syscalls** for a process.

Think of it as a firewall, but for system calls instead of network packets.

> If your app never needs to change its hostname, block the `sethostname` syscall entirely.

### seccomp Profile Types in Kubernetes

| `seccompProfile.type` | Description |
|-----------------------|-------------|
| `RuntimeDefault` | Safe baseline profile shipped with the container runtime |
| `Localhost` | Custom profile loaded from a file on the node |
| `Unconfined` | No restrictions (least secure) |

Configure seccomp in `securityContext` at the Pod or container level:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

For a hands-on localhost profile walkthrough, see [04-ApplyingALocalhostSeccompProfileToAPod](../04-ApplyingALocalhostSeccompProfileToAPod/readme.md).

## AppArmor

**AppArmor** is a Linux Security Module (LSM) that limits what programs can do — but instead of filtering syscalls, it controls:

- File access (read/write paths)
- Network permissions
- Process capabilities

AppArmor applies rules based on the **executable path**. For example, you can attach a profile to `nginx` that defines which files it can read, which ports it can bind to, and whether it can execute other processes.

In Kubernetes, AppArmor is applied via **Pod annotations**:

```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-default
```

## Two-Layer Defense

| Layer | Tool | What it controls |
|-------|------|------------------|
| Syscall filtering | seccomp | Which kernel calls are allowed |
| Access control | AppArmor | What those calls can actually do (files, network, capabilities) |

Together, seccomp and AppArmor form a strong defense-in-depth strategy at the kernel level.

## Example Pod Manifest

See `seccomp-apparmor-pod.yaml` for a combined example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened-nginx
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-default
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:1.25
```

- **seccomp** ensures only safe syscalls are allowed.
- **AppArmor** ensures nginx only interacts with approved files and networks.

## Best Practices

1. **Default to `RuntimeDefault` seccomp** unless you have a specific reason not to — it provides solid out-of-the-box protection.
2. **Use AppArmor** on supported nodes, especially for internet-exposed or sensitive-data workloads.
3. **Test with restrictive profiles before production** — some apps need syscalls you might not expect.
4. **Document required syscalls** to justify any exceptions — transparency helps maintain security hygiene.
5. **Combine with PSA** for layered defense — PSA handles Pod-level rules; seccomp and AppArmor secure kernel-level interactions.

## Key Takeaway

seccomp filters syscalls; AppArmor restricts file and network access. Use both alongside Pod Security Admission to minimize attack surface while maintaining workload reliability.
