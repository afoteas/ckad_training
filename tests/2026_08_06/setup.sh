#!/usr/bin/env bash
# CKAD Simulation Exam 2026-08-06 — seed / reset
# Usage:
#   bash setup.sh          # namespaces + seeds + kustomize base + local helm chart
#   bash setup.sh --reset   # tear down
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=(batch storage release settings access hardened capacity edge mesh ops-tools triage)

if ! kubectl get --raw /readyz >/dev/null 2>&1; then
  cat >&2 <<'MSG'
!! Cluster unreachable. Bring it back before seeding:

     sudo service docker start
     docker start ckad-control-plane ckad-worker ckad-worker2 ckad-worker3
     kind export kubeconfig --name ckad
     kubectl config use-context kind-ckad

   If the cluster is gone entirely, recreate it, then re-run this script.
MSG
  exit 1
fi

reset() {
  echo ">> Deleting exam namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl delete ns "$ns" --ignore-not-found --wait=false
  done
  echo ">> Deleting cluster-scoped exam objects..."
  kubectl delete pv archive-pv --ignore-not-found --wait=false
  helm uninstall frontdoor -n release >/dev/null 2>&1 || true
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
kubectl label ns ops-tools team=ops --overwrite >/dev/null

echo ">> [Q7] Seeding Deployment payments in release (4 revisions, head is broken)..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments
  namespace: release
  labels: {app: payments}
spec:
  replicas: 3
  selector: {matchLabels: {app: payments}}
  template:
    metadata: {labels: {app: payments}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports: [{containerPort: 80}]
YAML
kubectl -n release annotate deploy payments kubernetes.io/change-cause="initial rollout nginx:1.24" --overwrite >/dev/null
kubectl -n release rollout status deploy payments --timeout=120s >/dev/null || true

# Annotate only after each new ReplicaSet exists, otherwise the change-cause lands on
# the outgoing revision and the whole history reads one step behind.
for tag in 1.25 1.26; do
  kubectl -n release set image deploy/payments nginx="nginx:${tag}" >/dev/null
  kubectl -n release rollout status deploy payments --timeout=120s >/dev/null || true
  kubectl -n release annotate deploy payments \
    kubernetes.io/change-cause="bump nginx:${tag}" --overwrite >/dev/null
done

# Head revision: typo in the tag -> ImagePullBackOff, rollout wedges part-way through.
kubectl -n release set image deploy/payments nginx=nginx:1.27-alpinee >/dev/null
sleep 5
kubectl -n release annotate deploy payments \
  kubernetes.io/change-cause="bump nginx:1.27-alpinee" --overwrite >/dev/null

echo ">> [Q13/Q14] Seeding web-tier, shop-ui, shop-api in edge..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-tier
  namespace: edge
  labels: {app: web-tier}
spec:
  replicas: 2
  selector: {matchLabels: {app: web-tier}}
  template:
    metadata: {labels: {app: web-tier}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-ui
  namespace: edge
  labels: {app: shop-ui}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop-ui}}
  template:
    metadata: {labels: {app: shop-ui}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: shop-ui
  namespace: edge
spec:
  selector: {app: shop-ui}
  ports: [{port: 80, targetPort: 80}]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-api
  namespace: edge
  labels: {app: shop-api}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop-api}}
  template:
    metadata: {labels: {app: shop-api}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports: [{containerPort: 80}]
---
apiVersion: v1
kind: Service
metadata:
  name: shop-api
  namespace: edge
spec:
  selector: {app: shop-api}
  ports: [{port: 8080, targetPort: 80}]
YAML

echo ">> [Q15] Seeding api / frontend / other pods in mesh, tooling pod in ops-tools..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: mesh
  labels: {app: api}
spec:
  replicas: 2
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: api
        image: nginx:1.25
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: mesh
  labels: {tier: frontend}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep infinity"]
---
apiVersion: v1
kind: Pod
metadata:
  name: other
  namespace: mesh
  labels: {tier: other}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep infinity"]
---
apiVersion: v1
kind: Pod
metadata:
  name: toolbox
  namespace: ops-tools
  labels: {app: toolbox}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep infinity"]
YAML

echo ">> [Q16] Seeding Deployment catalog (no probes) in triage..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
  namespace: triage
  labels: {app: catalog}
spec:
  replicas: 2
  selector: {matchLabels: {app: catalog}}
  template:
    metadata: {labels: {app: catalog}}
    spec:
      containers:
      - name: catalog
        image: nginx:1.25
        ports: [{containerPort: 80}]
YAML

echo ">> [Q17] Seeding three broken pods (alpha, beta, gamma) in triage..."
kubectl -n triage delete pod alpha beta gamma \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1 || true
kubectl -n triage delete cm gamma-config --ignore-not-found >/dev/null 2>&1 || true
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: alpha
  namespace: triage
  labels: {app: alpha}
spec:
  containers:
  - name: c
    image: nginx:1.25-alpin
---
apiVersion: v1
kind: Pod
metadata:
  name: beta
  namespace: triage
  labels: {app: beta}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "echo starting; exit 7"]
---
apiVersion: v1
kind: Pod
metadata:
  name: gamma
  namespace: triage
  labels: {app: gamma}
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep infinity"]
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: gamma-config
          key: db_host
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

echo ">> [Q5] Writing Helm chart to ${HERE}/localchart ..."
mkdir -p "${HERE}/localchart/templates"
cat > "${HERE}/localchart/Chart.yaml" <<'YAML'
apiVersion: v2
name: localchart
description: Minimal nginx chart for CKAD practice
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

mkdir -p "${HERE}/answers"

echo
echo ">> Seed complete. Namespaces: ${NAMESPACES[*]}"
echo ">> Helper assets: kustomize/base (Q6), localchart/ (Q5)."
echo ">> Pre-existing: payments (Q7), web-tier/shop-* (Q13,Q14), mesh pods (Q15), catalog (Q16)."
echo ">> Broken on purpose: triage/alpha, triage/beta, triage/gamma (Q17)."
echo
echo ">> Score yourself when done:  bash verify.sh"
echo ">> Start your 120-minute timer. Good luck!"
