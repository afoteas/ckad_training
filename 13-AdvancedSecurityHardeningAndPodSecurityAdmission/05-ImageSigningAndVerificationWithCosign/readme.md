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
| OCI image signing | Sign images stored in Docker Hub, GHCR, ECR, GCR, Harbor, `cgr.dev`, etc. |
| Signatures in registry | Signatures are stored alongside images — no separate database |
| Key-based signing | Traditional public/private key pair |
| Keyless signing | Uses OIDC identity (GitHub, Google) — no key rotation headaches |

## Install Cosign

### Linux / WSL

Download the latest release binary:

```bash
curl -fsSL -o cosign "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
chmod +x cosign
sudo mv cosign /usr/local/bin/cosign
cosign version
```

Official install options: [Sigstore Cosign installation](https://docs.sigstore.dev/cosign/system_config/installation/)

## Cosign Signing Workflow

```text
1. Build image locally   →  docker build
2. Push to registry      →  image must exist in the registry first
3. Sign image            →  cosign sign --key cosign.key <image>
4. Verify before deploy  →  cosign verify --key cosign.pub <image>
```

The signature is **pushed to the same registry** as the image (Docker Hub, GHCR, etc.) — it is not stored in git or inside the image layers.

## Hands-On: Sign a Custom Local Image

This walkthrough builds a small image on your machine, pushes it to a registry, signs it with Cosign, and verifies the signature.

### Step 1: Create a Simple Dockerfile

```bash
mkdir -p ~/cosign-demo && cd ~/cosign-demo

cat > Dockerfile <<'EOF'
FROM busybox:1.36
CMD ["echo", "hello from signed image again"]
EOF

docker build -t afoteas/cosign-demo:1.0 .
```

Replace `myuser` with your Docker Hub username, or use `ghcr.io/myorg/cosign-demo:1.0` for GitHub Container Registry.

### Step 2: Push the Image to a Registry

The image must be in a registry **before** you can sign it. Cosign attaches the signature to the image digest in that registry.

**Docker Hub:**

```bash
docker login
docker push afoteas/cosign-demo:1.0
```

**GitHub Container Registry:**

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USER --password-stdin
docker tag afoteas/cosign-demo:1.0 ghcr.io/afoteas/cosign-demo:1.0
docker push ghcr.io/afoteas/cosign-demo:1.0
```

> **kind note:** A image loaded with `kind load docker-image` exists only on the node — Cosign cannot sign it until it is pushed to an OCI registry. For local clusters, run a local registry (`localhost:5000`) or push to Docker Hub / GHCR.

### Step 3: Generate a Key Pair (one-time)

```bash
cosign generate-key-pair
```

This creates `cosign.key` (private) and `cosign.pub` (public). You will be prompted for a password to encrypt the private key.

Keep `cosign.key` secret — use it only in CI or on trusted machines. Distribute `cosign.pub` to anyone who needs to verify signatures.

### Step 4: Sign the Image

**Docker Hub:**

```bash
cosign sign --key cosign.key docker.io/afoteas/cosign-demo:1.0
```

**GHCR:**

```bash
cosign sign --key cosign.key ghcr.io/afoteas/cosign-demo:1.0
```

Cosign uploads the signature artifact to the registry. You need registry **write** access (same credentials as `docker push`).

Inspect what was attached:

```bash
cosign tree docker.io/myuser/cosign-demo:1.0
```

### Step 5: Verify the Signature

```bash
cosign verify --key cosign.pub docker.io/afoteas/cosign-demo:1.0
```

Expected output includes `Verified OK` when the signature matches and the image has not been tampered with.

If verification fails, common causes are:

- Image was re-pushed after signing (digest changed — sign again)
- Wrong public key
- Image was never signed

### Registry Comparison

| Registry | Signed by default? | Sign with Cosign? |
|----------|-------------------|-------------------|
| Docker Hub (`docker.io`) | No | Yes — same workflow |
| GHCR (`ghcr.io`) | No | Yes — same workflow |
| Chainguard (`cgr.dev`) | Yes (publisher-signed) | You can add your own signature too |

The Cosign commands are identical across registries — only the image reference changes.

### Keyless Signing (OIDC)

Keyless signing uses your **OIDC identity** (GitHub, Google, etc.) instead of a `cosign.key` file. Sigstore issues a short-lived certificate, signs the image, and records the signature in the **Rekor** transparency log.

| | Key-based | Keyless (OIDC) |
|---|-----------|----------------|
| Sign | `cosign sign --key cosign.key <image>` | `cosign sign <image>` |
| Verify | `cosign verify --key cosign.pub <image>` | `cosign verify --certificate-identity=... <image>` |
| Keys to manage | Yes | No |
| Best for | Local learning, air-gapped | CI/CD (GitHub Actions, etc.) |

```text
1. docker push ghcr.io/afoteas/cosign-demo:1.0
2. cosign sign ghcr.io/afoteas/cosign-demo:1.0   # no --key
3. Browser/OIDC login → Fulcio issues short-lived cert
4. Signature pushed to GHCR + entry in Rekor log
```

Push still comes first — keyless signing also attaches to the digest in the registry.

#### Interactive keyless sign (local machine)

```bash
# Registry auth still required
echo $GITHUB_TOKEN | docker login ghcr.io -u afoteas --password-stdin

docker push ghcr.io/afoteas/cosign-demo:1.0

# No --key — Cosign prompts for OIDC login (often opens a browser)
cosign sign ghcr.io/afoteas/cosign-demo:1.0
```

#### Verify a keyless signature

Keyless verify checks **who** signed the image, not a static public key:

```bash
# Verify signed by a specific GitHub user
cosign verify ghcr.io/afoteas/cosign-demo:1.0 \
  --certificate-identity="https://github.com/afoteas" \
  --certificate-oidc-issuer="https://github.com/login/oauth"
```

Inspect signatures attached to the image:

```bash
cosign tree ghcr.io/afoteas/cosign-demo:1.0
```

#### Keyless sign in GitHub Actions (recommended for CI)

This is the most common production pattern — OIDC token from GitHub, no key files in secrets:

```yaml
name: build-sign-push

on:
  push:
    branches: [main]

permissions:
  contents: read
  packages: write
  id-token: write    # required for keyless Cosign OIDC

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        id: build
        with:
          push: true
          tags: ghcr.io/afoteas/cosign-demo:1.0

      - uses: sigstore/cosign-installer@v3

      - name: Sign image (keyless)
        run: cosign sign ghcr.io/afoteas/cosign-demo:1.0
```

The workflow pushes first (via `build-push-action`), then signs. GitHub provides the OIDC token automatically — no browser step in CI.

Verify in CI or locally that the image was signed by your repo workflow:

```bash
cosign verify ghcr.io/afoteas/cosign-demo:1.0 \
  --certificate-identity-regexp="https://github.com/afoteas/.*" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```

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

- Registry must support storing OCI signature artifacts (Docker Hub, GHCR, GCR, ECR, Harbor, `cgr.dev` all work with Cosign).
- The image must be **pushed before signing** — Cosign signs the digest in the registry, not a local-only image.
- Test compatibility before enforcing in production — combine signing with admission policies for end-to-end supply chain security.

## CKAD Note

Cosign/Sigstore image signing (`cosign sign`, `cosign verify`, keyless OIDC, Rekor) is real-world supply-chain tooling and is **not on the CKAD exam** — treat this chapter as background.

- **Examinable and adjacent:** choosing trusted base images, referencing images by digest, and configuring `imagePullSecrets` for private registries.
- **Beyond scope (background here):** generating key pairs, `cosign sign/verify`, keyless signing with OIDC/Fulcio, and Rekor transparency logs.
- The exam-relevant idea to retain is that admission control can gate images at the cluster — the in-scope version of that is Pod Security Admission (chapters 01–02), not signature webhooks.

## Key Takeaway

Cosign brings cryptographic trust to the container lifecycle. Sign in CI/CD, verify at the cluster gate, and block anything that doesn't pass — the most impactful step for supply chain security.
