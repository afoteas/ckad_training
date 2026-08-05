#!/usr/bin/env bash
# CKAD Simulation Exam 2026-07-31 — seed / reset
# Usage:
#   bash setup.sh          # namespaces + seeds + kustomize base + local helm chart
#   bash setup.sh --reset   # tear down
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=(workloads deploy config rbac secure limits net observe)

reset() {
  echo ">> Deleting exam namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl delete ns "$ns" --ignore-not-found --wait=false
  done
  echo ">> Reset requested. Namespaces terminating."
  exit 0
}

if [[ "${1:-}" == "--reset" ]]; then
  reset
fi

echo ">> Creating namespaces..."
for ns in "${NAMESPACES[@]}"; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
done

echo ">> [Q7] Seeding Deployment 'payment-v1' + Service 'payment' in deploy..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-v1
  namespace: deploy
  labels: {app: payment, track: stable}
spec:
  replicas: 3
  selector: {matchLabels: {app: payment, track: stable}}
  template:
    metadata: {labels: {app: payment, track: stable}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: payment
  namespace: deploy
spec:
  selector: {app: payment}
  ports: [{port: 80, targetPort: 80}]
YAML

echo ">> [Q12] Seeding LimitRange in 'limits'..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: limits
spec:
  limits:
  - type: Container
    default: {cpu: 500m, memory: 256Mi}
    defaultRequest: {cpu: 100m, memory: 64Mi}
YAML

echo ">> [Q13] Seeding Deployment 'cache' in net..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
  namespace: net
  labels: {app: cache}
spec:
  replicas: 2
  selector: {matchLabels: {app: cache}}
  template:
    metadata: {labels: {app: cache}}
    spec:
      containers:
      - name: redis
        image: redis:7
        ports: [{containerPort: 6379}]
YAML

echo ">> [Q14] Seeding 'secure-site' Deployment + Service + TLS secret in net..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-site
  namespace: net
  labels: {app: secure-site}
spec:
  replicas: 1
  selector: {matchLabels: {app: secure-site}}
  template:
    metadata: {labels: {app: secure-site}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: secure-site
  namespace: net
spec:
  selector: {app: secure-site}
  ports: [{port: 80, targetPort: 80}]
YAML

if ! kubectl -n net get secret site-tls >/dev/null 2>&1; then
  TMP=$(mktemp -d)
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
    -subj "/CN=www.example.com/O=example" >/dev/null 2>&1
  kubectl -n net create secret tls site-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key"
  rm -rf "$TMP"
fi

echo ">> [Q15] Seeding 'db' pods and a 'tier=api' pod in net..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: net
  labels: {app: db}
spec:
  replicas: 1
  selector: {matchLabels: {app: db}}
  template:
    metadata: {labels: {app: db}}
    spec:
      containers:
      - name: pg
        image: nginx:1.25   # stand-in listening container
        ports: [{containerPort: 5432}]
---
apiVersion: v1
kind: Pod
metadata:
  name: api-client
  namespace: net
  labels: {tier: api}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
YAML

echo ">> [Q16] Seeding broken Deployment 'broken-cfg' (missing ConfigMap) in observe..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-cfg
  namespace: observe
  labels: {app: broken-cfg}
spec:
  replicas: 2
  selector: {matchLabels: {app: broken-cfg}}
  template:
    metadata: {labels: {app: broken-cfg}}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh","-c","echo $SETTING_A; sleep 3600"]
        envFrom:
        - configMapRef:
            name: app-settings   # <-- this ConfigMap does not exist -> CreateContainerConfigError
YAML

echo ">> [Q17] Seeding 'bad-image' pod (bad tag -> ImagePullBackOff) in observe..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: bad-image
  namespace: observe
  labels: {app: bad-image}
spec:
  containers:
  - name: app
    image: nginx:1.25-doesnotexist   # <-- nonexistent tag
    ports: [{containerPort: 80}]
YAML

echo ">> [Q6] Writing Kustomize base to ${HERE}/kustomize/base ..."
mkdir -p "${HERE}/kustomize/base"
cat > "${HERE}/kustomize/base/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels: {app: frontend}
spec:
  replicas: 1
  selector: {matchLabels: {app: frontend}}
  template:
    metadata: {labels: {app: frontend}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports: [{containerPort: 80}]
YAML
cat > "${HERE}/kustomize/base/kustomization.yaml" <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
YAML

echo ">> [Q5] Writing local Helm chart to ${HERE}/localchart (offline fallback) ..."
mkdir -p "${HERE}/localchart/templates"
cat > "${HERE}/localchart/Chart.yaml" <<'YAML'
apiVersion: v2
name: localchart
description: Minimal apache-like chart for CKAD practice (offline fallback)
type: application
version: 0.1.0
appVersion: "2.4"
YAML
cat > "${HERE}/localchart/values.yaml" <<'YAML'
replicaCount: 1
image: httpd:2.4
YAML
cat > "${HERE}/localchart/templates/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-apache
  labels: {app: {{ .Release.Name }}}
spec:
  replicas: {{ .Values.replicaCount }}
  selector: {matchLabels: {app: {{ .Release.Name }}}}
  template:
    metadata: {labels: {app: {{ .Release.Name }}}}
    spec:
      containers:
      - name: apache
        image: {{ .Values.image }}
        ports: [{containerPort: 80}]
YAML

echo
echo ">> Seed complete. Namespaces: ${NAMESPACES[*]}"
echo ">> Helper assets: kustomize/base (Q6), localchart/ (Q5 fallback)."
echo ">> Debug seeds in 'observe': broken-cfg (missing ConfigMap), bad-image (bad tag)."
echo ">> Start your 120-minute timer. Good luck!"
