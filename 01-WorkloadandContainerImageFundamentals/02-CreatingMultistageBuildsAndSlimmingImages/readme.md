# Creating Multi-Stage Builds and Slimming Images

This lesson demonstrates how multi-stage Docker builds reduce image size and attack surface by separating build-time dependencies from runtime artifacts.

## Why Multi-Stage Builds

Single-stage images often include compilers, package managers, and temporary build files in the final runtime image.

Multi-stage pattern:

1. Build stage: compile the application using full toolchain.
2. Runtime stage: copy only final executable/artifacts into a minimal base.

Result:

- much smaller images
- faster push/pull and startup times
- reduced CVE exposure

## Demo Files

- `main.go`
- `Dockerfile`

## Build Flow

### 1) Build the image

```bash
docker build -t app-demo:multi-stage .
```

### 2) Inspect final size

```bash
docker images app-demo:multi-stage
```

In the demo, the multi-stage image is dramatically smaller than a single-stage equivalent.

### 3) Run and verify

```bash
docker run --rm -p 8080:8080 app-demo:multi-stage
curl http://localhost:8080
```

## Stage Design Summary

### Stage 1: Builder

- use `golang` builder image
- copy source code
- compile binary

### Stage 2: Minimal Runtime

- use minimal base (`alpine` or `scratch`)
- copy only compiled binary from builder
- run as non-root user
- expose app port and start process

## Key Line in Multi-Stage Dockerfile

```dockerfile
COPY --from=builder /app/app /app/app
```

This is the critical handoff that keeps heavy build tools out of the final image.

## Best Practices Applied

1. keep final stage minimal
2. run as non-root user
3. avoid copying unnecessary files into runtime image
4. optimize layer order for cache efficiency

## Expected Outcome

- substantial image size reduction (often 80% to 95%)
- lower registry transfer time
- smaller runtime attack surface

## Summary

Multi-stage builds are a core production practice for Kubernetes images: build with full tooling, ship only what is required to run.

## CKAD Tips

- Multi-stage builds are the exam-friendly way to modify and slim images: a `builder` stage compiles, a minimal final stage runs.
- The critical line is `COPY --from=builder ...` — it copies only the artifact and leaves the toolchain behind.
- Use `alpine` or `scratch` for the final stage and run as a non-root user to minimize size and attack surface.
- Verify size with `docker images app-demo:multi-stage` and behavior with `docker run --rm -p 8080:8080 ...` before pushing.

## Key Takeaway

Build with the full toolchain but ship only the compiled artifact — multi-stage builds cut image size (often 80–95%) and attack surface without changing application behavior.
