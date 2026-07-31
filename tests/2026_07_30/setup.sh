#!/usr/bin/env bash
# CKAD Practice Exam 2026-07-30 — seed / reset
# Usage:
#   bash setup.sh          # namespaces + seeds + kustomize base + local helm chart
#   bash setup.sh --reset   # tear down
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=(build deploy config rbac secure storage net net-clients observe)

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
kubectl label ns net-clients access=allowed --overwrite

echo ">> [Q7] Seeding Deployment 'web-app' (nginx:1.24) in deploy..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: deploy
  labels: {app: web-app}
spec:
  replicas: 3
  selector: {matchLabels: {app: web-app}}
  template:
    metadata: {labels: {app: web-app}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports: [{containerPort: 80}]
YAML

echo ">> [Q13/Q15] Seeding Deployment 'api' + no service (student makes it) in net..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: net
  labels: {app: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
YAML

echo ">> [Q14] Seeding 'shop' and 'blog' Deployments + Services in net..."
for app in shop blog; do
cat <<YAML | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app}
  namespace: net
  labels: {app: ${app}}
spec:
  replicas: 1
  selector: {matchLabels: {app: ${app}}}
  template:
    metadata: {labels: {app: ${app}}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: ${app}
  namespace: net
spec:
  selector: {app: ${app}}
  ports: [{port: 80, targetPort: 80}]
YAML
done

echo ">> [Q15] Seeding 'caller' pod in net-clients..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: caller
  namespace: net-clients
  labels: {app: caller}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
YAML

echo ">> [Q16] Seeding broken Deployment 'flaky' (readiness probe on wrong port) in observe..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flaky
  namespace: observe
  labels: {app: flaky}
spec:
  replicas: 2
  selector: {matchLabels: {app: flaky}}
  template:
    metadata: {labels: {app: flaky}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
        readinessProbe:
          httpGet: {path: /, port: 8080}   # <-- wrong port; nginx listens on 80
          initialDelaySeconds: 3
          periodSeconds: 5
YAML

echo ">> [Q18] Seeding CrashLoopBackOff pod 'crasher' in observe..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: crasher
  namespace: observe
  labels: {app: crasher}
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh","-c","echo starting up; sleep 3; echo FATAL: config missing; exit 1"]
  restartPolicy: Always
YAML

echo ">> [Q6] Writing Kustomize base to ${HERE}/kustomize/base ..."
mkdir -p "${HERE}/kustomize/base"
cat > "${HERE}/kustomize/base/deployment.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kbase
  labels: {app: kbase}
spec:
  replicas: 1
  selector: {matchLabels: {app: kbase}}
  template:
    metadata: {labels: {app: kbase}}
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
description: Minimal nginx chart for CKAD practice (offline fallback)
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
echo ">> Helper assets:"
echo "   - Kustomize base : ${HERE}/kustomize/base   (Q6 — build your overlay under answers/kustomize/overlay)"
echo "   - Local Helm chart: ${HERE}/localchart        (Q5 — offline fallback)"
echo ">> Debug seeds: observe/flaky (never Ready), observe/crasher (CrashLoop)."
echo ">> Start your 120-minute timer. Good luck!"
