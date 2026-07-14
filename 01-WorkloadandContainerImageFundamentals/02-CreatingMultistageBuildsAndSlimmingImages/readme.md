# Creating Multi-Stage Builds and Slimming Images

## Scenario
Build a minimal Go HTTP server using a Docker multi-stage build. The first stage compiles
the binary using the full `golang:1.21-alpine` toolchain. The second stage copies only
the compiled binary into a lean `alpine` image, dropping all build tools, source code,
and intermediate layers from the final image.

## Why multi-stage builds?
| Single-stage (golang:alpine) | Multi-stage (alpine runtime) |
|---|---|
| ~300 MB+ | ~10–15 MB |
| Contains compiler, source, build cache | Contains only the binary |
| Large attack surface | Minimal attack surface |
| Slower to push/pull | Faster to distribute |

## Dockerfile structure

```
Stage 1 — builder (golang:1.21-alpine)
  └── Compiles main.go → statically linked binary /app/app

Stage 2 — runtime (alpine:latest)
  └── COPY --from=builder /app/app
  └── Runs as unprivileged user (appuser)
  └── Exposes port 8080
```

## Steps

### 1. Build the image
```bash
docker build -t go-web-app:slim .
```

### 2. Compare image sizes
```bash
# Check the final image size
docker images go-web-app:slim

# Compare against a single-stage golang build
docker images golang:1.21-alpine
```
The final image should be dramatically smaller than the builder stage.

### 3. Run the container and test it
```bash
docker run -d -p 8080:8080 --name go-app go-web-app:slim
curl http://localhost:8080
```
Expected response: `Hello from the small, secure container!`

### 4. Inspect the layers
```bash
docker history go-web-app:slim
```
Notice there are very few layers and no trace of the Go toolchain.

### 5. Verify the process runs as a non-root user
```bash
docker exec go-app whoami
```
Expected output: `appuser`

### 6. Clean up
```bash
docker stop go-app && docker rm go-app
```

## Key techniques used

### Static binary (`-ldflags="-s -w"`)
```dockerfile
RUN go build -ldflags="-s -w" -o /app/app main.go
```
- `-s` strips the symbol table
- `-w` strips DWARF debug info
- Result: smaller binary with no debug metadata

### `COPY --from=builder`
```dockerfile
COPY --from=builder /app/app .
```
This is the core of multi-stage builds — only the compiled artifact crosses into the
final image. All build tooling stays in the builder stage and is discarded.

### Non-root user
```dockerfile
RUN adduser -D appuser
USER appuser
```
Running as an unprivileged user is a security best practice. If the container is
compromised, the attacker has no root privileges on the host.

## Notes
- For an even smaller image, replace `alpine:latest` with `scratch` (zero bytes base),
  but you must ensure the binary is fully statically linked (no libc dependencies).
- `docker scout cves go-web-app:slim` or `trivy image go-web-app:slim` can be used to
  verify the reduced CVE surface of the slim image vs. the builder stage.
