# Image Signing and Verification with Cosign

After securing Pods and the kernel, the next critical area is the **software supply chain** — ensuring container images are authentic and untampered.

## The Supply Chain Problem

When you pull an image from Docker Hub, ECR, or another registry, how do you know:

- The image wasn't modified in transit?
- It was actually built by your CI/CD pipeline?
- No one injected malware into the image?

Without signing, there is **no way to confirm authenticity**. Anyone could replace an image and your cluster would run it without complaint.

| Without signing | With signing |
|-----------------|--------------|
| No authenticity guarantee | Cryptographic proof of origin |
| Vulnerable to supply chain attacks | Tampering is detectable |
| Hard to enforce trust policies | Only signed images are allowed |

## What Image Signing Does

Cryptographic signing lets you:

- **Prove** an image came from a trusted source
- **Detect** tampering or unauthorized modifications
- **Enforce** policies so only signed images run in the cluster

## Sigstore Cosign

**Cosign** is an open-source tool under the [Sigstore](https://www.sigstore.dev/) project that makes digital signing and verification simple for container images.

### Key Features

| Feature | Description |
|---------|-------------|
| OCI image signing | Sign images stored in Docker Hub, ECR, GCR, Harbor, etc. |
| Signatures in registry | Signatures are stored alongside images — no separate database |
| Key-based signing | Traditional public/private key pair |
| Keyless signing | Uses OIDC identity (GitHub, Google) — no key rotation headaches |

## Cosign Signing Workflow

```text
1. Build image        →  docker build / CI pipeline
2. Sign image         →  cosign sign --key cosign.key <image>
3. Push to registry   →  signature stored alongside image
4. Verify at deploy   →  cosign verify --key cosign.pub <image>
```

### Step 1: Generate a Key Pair (one-time)

```bash
cosign generate-key-pair
```

This creates `cosign.key` (private) and `cosign.pub` (public).

### Step 2: Sign an Image

```bash
cosign sign --key cosign.key <registry>/<image>:<tag>
```

Cosign creates a digital signature and attaches it to the image in the registry.

### Step 3: Verify Before Deploying

```bash
cosign verify --key cosign.pub <registry>/<image>:<tag>
```

If the signature checks out, the image was built by your trusted pipeline and hasn't been tampered with.

### Keyless Signing (OIDC)

```bash
cosign sign <registry>/<image>:<tag>
```

Uses your OIDC identity (GitHub Actions, Google account) instead of managing key pairs. Signatures are recorded in Rekor transparency logs.

## Admission Control Integration

Signing alone is not enough — enforce verification at the **cluster level**:

1. Sign images in your CI/CD pipeline.
2. Push signed images to the registry.
3. Configure an **admission webhook** that checks signatures before Pods are created.
4. Unsigned or tampered images are **blocked** at the gate.

Think of it as airport security: every container is checked before entering the cluster.

For a hands-on webhook setup, see [06-VerifyingImageSignaturesViaImagePolicyWebhook](../06-VerifyingImageSignaturesViaImagePolicyWebhook/readme.md).

## Benefits and Considerations

### Benefits

- **Provenance** — prove exactly where an image came from and who built it (critical for compliance).
- **Reduced risk** — block untrusted workloads, especially from external sources.
- **CI/CD integration** — add `cosign sign` as a single step in your build pipeline.

### Considerations

- Registry must support storing signatures (GCR, ECR, Harbor — adoption is growing).
- Test compatibility before enforcing in production — not all registries support Sigstore yet.
- Combine signing with admission policies for end-to-end supply chain security.

## Key Takeaway

Cosign brings cryptographic trust to the container lifecycle. Sign in CI/CD, verify at the cluster gate, and block anything that doesn't pass — the most impactful step for supply chain security.
