#!/usr/bin/env bash
# CKAD Simulation Exam 2026-08-01 — seed / reset
# Usage:
#   bash setup.sh          # namespaces + seeds + kustomize base + local helm chart
#   bash setup.sh --reset   # tear down
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=(batch release settings identity hardened quota mesh triage)

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

echo ">> [Q7] Seeding checkout-stable + Service checkout in release..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-stable
  namespace: release
  labels: {component: checkout, track: stable}
spec:
  replicas: 3
  selector: {matchLabels: {component: checkout, track: stable}}
  template:
    metadata: {labels: {component: checkout, track: stable}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: checkout
  namespace: release
spec:
  selector: {component: checkout}
  ports: [{port: 80, targetPort: 80}]
YAML

echo ">> [Q12] Seeding LimitRange in quota..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: defaults
  namespace: quota
spec:
  limits:
  - type: Container
    default: {cpu: 500m, memory: 256Mi}
    defaultRequest: {cpu: 100m, memory: 64Mi}
YAML

echo ">> [Q13] Seeding Deployment broker in mesh..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broker
  namespace: mesh
  labels: {app: broker}
spec:
  replicas: 2
  selector: {matchLabels: {app: broker}}
  template:
    metadata: {labels: {app: broker}}
    spec:
      containers:
      - name: kafka
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
        ports: [{containerPort: 9092}]
YAML

echo ">> [Q14] Seeding shop-api + Service + TLS secret in mesh..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-api
  namespace: mesh
  labels: {app: shop-api}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop-api}}
  template:
    metadata: {labels: {app: shop-api}}
    spec:
      containers:
      - name: api
        image: nginx:1.25
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata:
  name: shop-api
  namespace: mesh
spec:
  selector: {app: shop-api}
  ports: [{port: 8080, targetPort: 8080}]
YAML

if ! kubectl -n mesh get secret shop-tls >/dev/null 2>&1; then
  TMP=$(mktemp -d)
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
    -subj "/CN=api.shop.internal/O=shop" >/dev/null 2>&1
  kubectl -n mesh create secret tls shop-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key"
  rm -rf "$TMP"
fi

echo ">> [Q15] Seeding frontend/backend pods in mesh..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: mesh
  labels: {role: backend}
spec:
  replicas: 1
  selector: {matchLabels: {role: backend}}
  template:
    metadata: {labels: {role: backend}}
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend-probe
  namespace: mesh
  labels: {role: frontend}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
YAML

echo ">> [Q16] Seeding broken Deployment miswired (probe on wrong port) in triage..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: miswired
  namespace: triage
  labels: {app: miswired}
spec:
  replicas: 2
  selector: {matchLabels: {app: miswired}}
  template:
    metadata: {labels: {app: miswired}}
    spec:
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "echo $API_MODE; sleep 3600"]
        env:
        - name: API_MODE
          value: live
        ports: [{containerPort: 8080}]
        readinessProbe:
          httpGet:
            path: /
            port: 9090
          initialDelaySeconds: 2
          periodSeconds: 3
YAML

echo ">> [Q17] Seeding flapper pod (CrashLoopBackOff) in triage..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: flapper
  namespace: triage
  labels: {app: flapper}
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "exit 1"]
YAML

echo ">> [Q6] Writing Kustomize base to ${HERE}/kustomize/base ..."
mkdir -p "${HERE}/kustomize/base"
cat > "${HERE}/kustomize/base/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels: {app: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
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
description: Minimal nginx-like chart for CKAD practice (offline fallback)
type: application
version: 0.1.0
appVersion: "1.25"
YAML
cat > "${HERE}/localchart/values.yaml" <<'YAML'
replicaCount: 1
image: nginx:1.25
YAML
cat > "${HERE}/localchart/templates/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-nginx
  labels: {app: {{ .Release.Name }}}
spec:
  replicas: {{ .Values.replicaCount }}
  selector: {matchLabels: {app: {{ .Release.Name }}}}
  template:
    metadata: {labels: {app: {{ .Release.Name }}}}
    spec:
      containers:
      - name: nginx
        image: {{ .Values.image }}
        ports: [{containerPort: 80}]
YAML

echo
echo ">> Seed complete. Namespaces: ${NAMESPACES[*]}"
echo ">> Helper assets: kustomize/base (Q6), localchart/ (Q5 fallback)."
echo ">> Debug seeds in triage: miswired (bad readiness probe), flapper (crash loop)."
echo ">> Start your 120-minute timer. Good luck!"
