#!/usr/bin/env bash
# CKAD Simulation Exam 2026-08-02 — seed / reset
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=(agents release platform policy edge triage edge-monitors)

reset() {
  echo ">> Deleting exam namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl delete ns "$ns" --ignore-not-found --wait=false
  done
  echo ">> Waiting for namespaces to terminate..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl wait --for=delete "namespace/$ns" --timeout=120s 2>/dev/null || true
  done
  echo ">> Removing exam node labels/taints from worker3..."
  kubectl label node ckad-worker3 workload- 2>/dev/null || true
  kubectl taint node ckad-worker3 dedicated- 2>/dev/null || true
  echo ">> Reset complete."
  exit 0
}

if [[ "${1:-}" == "--reset" ]]; then
  reset
fi

EDGE_NODE="${EDGE_NODE:-ckad-worker3}"

ensure_namespace() {
  local ns="$1"
  local phase
  phase="$(kubectl get ns "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo NotFound)"
  case "$phase" in
    Active)
      return 0
      ;;
    Terminating)
      echo ">> Waiting for namespace '$ns' to finish terminating..."
      kubectl wait --for=delete "namespace/$ns" --timeout=120s
      kubectl create ns "$ns"
      ;;
    NotFound)
      kubectl create ns "$ns"
      ;;
    *)
      echo ">> Namespace '$ns' in unexpected phase '$phase'; recreating..."
      kubectl delete ns "$ns" --ignore-not-found --wait=true --timeout=120s
      kubectl create ns "$ns"
      ;;
  esac
}

echo ">> Creating namespaces..."
for ns in agents release platform policy edge triage edge-monitors; do
  ensure_namespace "$ns"
done
kubectl label ns edge-monitors zone=monitoring --overwrite

echo ">> Preparing edge node ${EDGE_NODE} (label workload=edge, taint dedicated=exam:NoSchedule)..."
kubectl label node "$EDGE_NODE" workload=edge --overwrite
kubectl taint node "$EDGE_NODE" dedicated=exam:NoSchedule --overwrite

echo ">> Writing localchart to ${HERE}/localchart ..."
mkdir -p "${HERE}/localchart/templates"
cat > "${HERE}/localchart/Chart.yaml" <<'YAML'
apiVersion: v2
name: localchart
description: Minimal chart for CKAD Helm upgrade/rollback practice
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
  name: {{ .Release.Name }}-portal
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: portal
        image: {{ .Values.image }}
        ports:
        - containerPort: 80
YAML

echo ">> [Q7] Seeding shop-blue + Service shop in release..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-blue
  namespace: release
  labels: {app: shop, track: blue}
spec:
  replicas: 3
  selector: {matchLabels: {app: shop, track: blue}}
  template:
    metadata: {labels: {app: shop, track: blue}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: shop
  namespace: release
spec:
  selector: {app: shop}
  ports: [{port: 80, targetPort: 80}]
YAML

echo ">> [Q5/Q6] Installing Helm release portal in release..."
helm uninstall portal -n release 2>/dev/null || true
helm install portal "${HERE}/localchart" -n release \
  --set replicaCount=1 --set image=nginx:1.25

echo ">> [Q10] Seeding Deployment api in platform..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: platform
  labels: {app: api}
spec:
  replicas: 3
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
YAML

echo ">> [Q14] Seeding frontend + backend pods in edge..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: edge
  labels: {app: frontend}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: edge
  labels: {app: backend}
spec:
  containers:
  - name: api
    image: nginx:1.25
    ports: [{containerPort: 8080}]
YAML

echo ">> [Q15] Seeding exporter pod in edge..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: exporter
  namespace: edge
  labels: {app: exporter}
spec:
  containers:
  - name: metrics
    image: nginx:1.25
    ports: [{containerPort: 9100}]
YAML

echo ">> [Q16] Seeding Pending pod blocked (targets tainted edge node, no toleration) in triage..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: blocked
  namespace: triage
  labels: {app: blocked}
spec:
  nodeSelector:
    workload: edge
  containers:
  - name: diag
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
YAML

echo ">> [Q17] Seeding Deployment autoscaled in triage..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: autoscaled
  namespace: triage
  labels: {app: autoscaled}
spec:
  replicas: 2
  selector: {matchLabels: {app: autoscaled}}
  template:
    metadata: {labels: {app: autoscaled}}
    spec:
      containers:
      - name: app
        image: nginx:1.25
        ports: [{containerPort: 80}]
        resources:
          requests: {cpu: 100m, memory: 128Mi}
          limits: {cpu: 200m, memory: 256Mi}
YAML

echo ">> Checking metrics-server (required for Q17 HPA)..."
if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  echo ">> Installing metrics-server..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' \
    2>/dev/null || true
fi

echo
echo ">> Seed complete. Namespaces: agents release platform policy edge triage edge-monitors"
echo ">> Edge node: ${EDGE_NODE} (label workload=edge, taint dedicated=exam:NoSchedule)"
echo ">> Helm release 'portal' in release (Q5/Q6). metrics-server for Q17."
echo ">> Start your 120-minute timer. Good luck!"
