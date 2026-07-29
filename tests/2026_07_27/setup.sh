#!/usr/bin/env bash
# Setup for the 2026-07-27 CKAD practice exam.
# Creates all exam namespaces and the pre-existing objects that "fix it" tasks depend on.
#
#   bash setup.sh            # create namespaces + seed objects
#   bash setup.sh --reset    # delete exam namespaces first, then recreate
set -euo pipefail

NAMESPACES=(
  ckad-web
  ckad-config
  ckad-health
  ckad-batch
  ckad-design
  ckad-rbac
  ckad-netpol
  ckad-storage
)

if [[ "${1:-}" == "--reset" ]]; then
  echo ">> Resetting: deleting exam namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl delete namespace "$ns" --ignore-not-found --wait=false
  done
  echo ">> Waiting for namespaces to terminate..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl wait --for=delete "namespace/$ns" --timeout=90s 2>/dev/null || true
  done
  exit 0
fi

echo ">> Creating namespaces..."
for ns in "${NAMESPACES[@]}"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo ">> Q9: seeding broken-app in ckad-health (student must fix)..."
# Broken on purpose:
#   1. image tag does not exist (nginx:1.99-does-not-exist -> ImagePullBackOff)
#   2. readiness probe points at the wrong port (8080) so it would never be Ready even if it pulled
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: ckad-health
  labels:
    app: broken-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: web
        image: nginx:1.99-does-not-exist
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
EOF

echo ">> Q14: seeding api + client pods and api Service in ckad-netpol..."
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api
  namespace: ckad-netpol
  labels:
    app: api
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: ckad-netpol
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: ckad-netpol
  labels:
    app: client
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

echo ""
echo ">> Setup complete. Namespaces ready:"
kubectl get ns | grep ckad- || true
echo ""
echo ">> Q9 seed (should look unhealthy):"
kubectl get deploy broken-app -n ckad-health 2>/dev/null || true
echo ""
echo "Start your timer. Good luck!"
