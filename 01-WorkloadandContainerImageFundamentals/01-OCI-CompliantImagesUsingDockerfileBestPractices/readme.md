# OCI-Compliant Images Using Dockerfile Best Practices

This lesson explains why OCI-compliant image construction is essential for secure, portable, and repeatable Kubernetes deployments.

## Why OCI Compliance Matters

The Open Container Initiative (OCI) standard defines image format and runtime behavior. When your image follows OCI conventions:

- images built with one tool can run with another
- teams avoid tool lock-in
- CI and local builds produce predictable artifacts
- "works on my machine" problems are reduced

For Kubernetes and CKAD workflows, OCI consistency is a practical must-have skill.

## Core Dockerfile Best Practices

1. Use minimal base images when possible.
2. Pin exact image and dependency versions.
3. Prefer multi-stage builds to separate build tools from runtime.
4. Order instructions for better layer cache reuse.
5. Combine package-install commands into one RUN step.
6. Run as non-root user.
7. Use COPY instead of ADD unless ADD behavior is required.
8. Exclude unnecessary build context with .dockerignore.
9. Never bake secrets into image layers.

## Recommended Build Structure

A clear 4-step Dockerfile flow:

1. Select base image.
2. Install required runtime packages.
3. Copy source and set WORKDIR.
4. Define ENTRYPOINT and CMD explicitly.

## Security Guidance

- Keep base images updated for CVE patches.
- Reduce attack surface by removing unnecessary tools.
- Scan images in CI before promotion.
- Inject secrets at runtime with Kubernetes Secrets.

## Common Anti-Patterns

- using mutable tags like latest
- installing curl/wget/shells in final runtime image when not needed
- using ADD for normal local file copy
- embedding API keys or passwords in Dockerfile

## Practical Validation Commands

```bash
# Build
 docker build -t my-app:1.0.0 .

# Inspect layers
 docker history my-app:1.0.0

# Run container as verification
 docker run --rm -p 8080:8080 my-app:1.0.0
```

## Summary

OCI-compliant, security-hardened Dockerfiles produce deterministic, portable images that behave consistently across local development, CI, and Kubernetes runtime environments.

## CKAD Tips

- The "Application Design and Build" domain includes defining, building, and modifying container images — be comfortable with a basic `Dockerfile` and `docker build -t my-app:1.0.0 .`.
- Always pin image tags (never `latest`) and prefer minimal base images to reduce CVEs and pull time.
- Use `COPY` (not `ADD`) for local files and add a `.dockerignore` to shrink the build context.
- Run as a non-root `USER` and inject credentials at runtime via Kubernetes `Secret`s — never bake secrets into image layers.
- Combine `RUN` steps and order instructions for layer-cache reuse; inspect layers with `docker history my-app:1.0.0`.

## Key Takeaway

OCI-compliant, minimal, non-root Dockerfiles produce portable, deterministic images that behave the same across local development, CI, and Kubernetes.
