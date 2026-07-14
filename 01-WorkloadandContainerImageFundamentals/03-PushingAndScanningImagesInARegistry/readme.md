# Pushing and Scanning Images in a Registry

## Scenario
Build a intentionally vulnerable Python Flask app (`python:3.9-slim-buster` base),
push it to GitHub Container Registry (GHCR), and scan it for CVEs using Trivy.
Then practice rolling updates on a Kubernetes Deployment.

---

## Part 1 — Build, Tag, Push, and Scan

### 1. Build the image locally
```bash
docker build -t afoteas/python-web-app:v1.0 .
```
The Dockerfile uses `python:3.9-slim-buster` intentionally — an older base with known CVEs,
so Trivy has something to find.

### 2. Tag for GHCR
```bash
docker tag afoteas/python-web-app:v1.0 ghcr.io/afoteas/python-web-app:v1.0
```

### 3. Authenticate and push to GHCR
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <your-github-username> --password-stdin
docker push ghcr.io/afoteas/python-web-app:v1.0
```

### 4. Scan the local image for HIGH and CRITICAL vulnerabilities
```bash
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL afoteas/python-web-app:v1.0
```
Trivy pulls its vulnerability database and reports CVEs found in OS packages and
Python dependencies. Expect findings from the `buster` base image.

### 5. Scan the remote image in GHCR (optional)
```bash
docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL ghcr.io/afoteas/python-web-app:v1.0
```

---

## Part 2 — Rolling Updates on a Kubernetes Deployment

### 1. Pull and deploy an older nginx version
```bash
docker pull nginx:1.21.1
kubectl create deployment webserver --image=nginx:1.21.1 --replicas=3
kubectl get deployment webserver
kubectl get pods -l app=webserver
```

### 2. Update the image to a newer version (rolling update)
```bash
kubectl set image deployment/webserver nginx=nginx:1.25.5
kubectl rollout status deployment/webserver
```
Kubernetes performs a rolling update — old pods are replaced gradually with new ones.

### 3. Inspect the ReplicaSets created by the rollout
```bash
kubectl get rs -l app=webserver
```
You will see two ReplicaSets: the old one scaled to 0 and the new one at 3.

### 4. Check rollout history
```bash
kubectl rollout history deployment/webserver
```

### 5. Clean up
```bash
kubectl delete deployment webserver
```

---

## Notes
- `python:3.9-slim-buster` is based on Debian Buster (EOL). Switch to `python:3.9-slim-bookworm`
  to eliminate most OS-level CVEs.
- Trivy can also scan filesystem paths, Git repos, and Kubernetes clusters:
  ```bash
  docker run --rm aquasec/trivy:latest fs .
  ```
- `kubectl set image` is equivalent to editing the deployment image in `kubectl edit` but
  scriptable and audit-friendly.
- Each `kubectl set image` or `kubectl edit` that changes the pod template creates a new
  ReplicaSet and a new revision in rollout history.