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

### Preferred config: `securityContext` vs annotations

| | `securityContext.seccompProfile` | Legacy annotations |
|---|----------------------------------|--------------------|
| Status | GA since Kubernetes 1.19 | Deprecated |
| API validation | Yes — schema-checked | No — free-form strings |
| PSA `restricted` | **Required** here | Not sufficient on its own |
| CKAD | **Know this format** | Legacy; unlikely on new exams |

**Preferred (modern):**

```yaml
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
```

**Legacy (deprecated — do not use for new manifests):**

```yaml
metadata:
  annotations:
    seccomp.security.alpha.kubernetes.io/pod: runtime/default
    # per-container:
    container.seccomp.security.alpha.kubernetes.io/nginx: runtime/default
```

Always use `securityContext.seccompProfile`. Pod Security Admission's `restricted` standard checks this field, not seccomp annotations.

For a hands-on localhost profile walkthrough, see [04-ApplyingALocalhostSeccompProfileToAPod](../04-ApplyingALocalhostSeccompProfileToAPod/readme.md).

## AppArmor

**AppArmor** is a Linux Security Module (LSM) that limits what programs can do — but instead of filtering syscalls, it controls:

- File access (read/write paths)
- Network permissions
- Process capabilities

AppArmor applies rules based on the **executable path**. For example, you can attach a profile to `nginx` that defines which files it can read, which ports it can bind to, and whether it can execute other processes.

### Preferred config: `securityContext` vs annotations

| | `securityContext.appArmorProfile` | Legacy annotations |
|---|-----------------------------------|--------------------|
| Status | GA since Kubernetes 1.30 | Beta, still common |
| Scope | Per-container in `securityContext` | Per-container via annotation key |
| API validation | Yes | String parsed by kubelet |
| CKAD | Know for 1.30+ clusters | **Still the most common exam format** |

**Preferred on Kubernetes 1.30+:**

```yaml
spec:
  containers:
  - name: nginx
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: nginx-default
```

**Traditional (annotations — still widely used):**

```yaml
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/nginx: localhost/nginx-default
```

> **Note:** Some training slides place the AppArmor annotation key inside `securityContext`. That is incorrect — annotation keys belong under `metadata.annotations`. The `seccompProfile` field and AppArmor annotations serve different purposes and live in different parts of the manifest.

On **kind** clusters, AppArmor is often not enabled on node images. seccomp demos work out of the box; AppArmor examples may be silently ignored unless the node OS has AppArmor loaded.

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
2. **Use `securityContext` fields** for seccomp (always) and AppArmor (on 1.30+); know annotation syntax for older clusters and CKAD.
3. **Use AppArmor** on supported nodes, especially for internet-exposed or sensitive-data workloads.
4. **Test with restrictive profiles before production** — some apps need syscalls you might not expect.
5. **Document required syscalls** to justify any exceptions — transparency helps maintain security hygiene.
6. **Combine with PSA** for layered defense — PSA handles Pod-level rules; seccomp and AppArmor secure kernel-level interactions.

## CKAD Tips

- Know the modern field syntax: `spec.securityContext.seccompProfile.type: RuntimeDefault` — this is what PSA `restricted` requires. Learn the three types: `RuntimeDefault`, `Localhost`, `Unconfined`.
- `seccompProfile` can sit at Pod level (`spec.securityContext`) or per container; `appArmorProfile` is set per container in `securityContext`.
- Prefer `securityContext` fields over deprecated annotations — PSA checks the field, not annotations. Legacy AppArmor still uses the annotation `container.apparmor.security.beta.kubernetes.io/<container>`.
- Use `kubectl explain pod.spec.securityContext.seccompProfile` to recall the schema fast during the exam.
- On `kind` clusters AppArmor is often not loaded, so those examples may be silently ignored — seccomp works out of the box.

## Key Takeaway

seccomp filters syscalls; AppArmor restricts file and network access. Use both alongside Pod Security Admission to minimize attack surface while maintaining workload reliability.
