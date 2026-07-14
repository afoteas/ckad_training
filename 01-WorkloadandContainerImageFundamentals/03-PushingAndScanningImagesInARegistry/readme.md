# Pushing and Scanning Images in a Registry

This lesson covers a DevSecOps image flow:

1. build image
2. tag image for registry
3. push image
4. scan image for vulnerabilities
5. promote only if scan is acceptable

## Why This Matters

An image that runs locally can still carry high-risk CVEs. Security scanning must be part of image promotion before Kubernetes deployment.

## Demo Files

- `app.py`
- `requirements.txt`
- `Dockerfile`

## Build and Push Workflow

### 1) Build image

```bash
docker build -t <registry-user>/python-web-app:v1.0 .
```

### 2) Push image

```bash
docker push <registry-user>/python-web-app:v1.0
```

For Docker Hub, ensure login first:

```bash
docker login
```

## Scan with Trivy

Run Trivy in a temporary container to scan HIGH and CRITICAL issues:

```bash
docker run --rm aquasec/trivy:0.49.1 image --severity HIGH,CRITICAL <registry-user>/python-web-app:v1.0
```

What to look for:

- severity level
- affected package
- fixed version availability

If high/critical findings are unacceptable, do not promote this image.

## Secure Promotion Rule

Recommended sequence in CI:

1. build
2. test
3. scan
4. push/promote
5. deploy

This order prevents vulnerable artifacts from reaching runtime clusters.

## Hardening Follow-Ups

- update old base images to supported tags
- remove unused packages from Dockerfile
- rebuild and rescan regularly

## Summary

Image scanning is not optional in production Kubernetes delivery. Build and push speed is valuable, but secure promotion gates are essential.

## Previous Notes (Preserved)

The notes below are kept from the earlier version for reference.

### Scenario

Build an intentionally vulnerable Python Flask app (`python:3.9-slim-buster` base), push it to GitHub Container Registry (GHCR), and scan it for CVEs using Trivy.

### Build, Tag, Push, and Scan

```bash
# Build the image locally
docker build -t afoteas/python-web-app:v1.0 .

# Tag for GHCR
docker tag afoteas/python-web-app:v1.0 ghcr.io/afoteas/python-web-app:v1.0

# Authenticate and push to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin
docker push ghcr.io/afoteas/python-web-app:v1.0

# Scan local image for HIGH and CRITICAL vulnerabilities
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL afoteas/python-web-app:v1.0

# Scan remote image in GHCR (optional)
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL ghcr.io/afoteas/python-web-app:v1.0
```

### Related Rolling Update Commands (Reference)

```bash
docker pull nginx:1.21.1
kubectl create deployment webserver --image=nginx:1.21.1 --replicas=3
kubectl get deployment webserver
kubectl get pods -l app=webserver

kubectl set image deployment/webserver nginx=nginx:1.25.5
kubectl rollout status deployment/webserver

kubectl get rs -l app=webserver
kubectl rollout history deployment/webserver
kubectl delete deployment webserver
```

### Notes

- `python:3.9-slim-buster` is based on Debian Buster (EOL). Prefer newer maintained bases such as `python:3.9-slim-bookworm`.
- Trivy can also scan filesystem paths:

```bash
docker run --rm aquasec/trivy:latest fs .
```

- `kubectl set image` is script-friendly and creates new rollout revisions.