#!/usr/bin/env bash
# CKAD Practice Exam 2026-07-29 — seed / reset
# Usage:
#   bash setup.sh          # create namespaces + seed objects
#   bash setup.sh --reset   # tear everything down
set -euo pipefail

NAMESPACES=(exam-web exam-config exam-secure exam-quota exam-health exam-batch exam-sched exam-net exam-clients)

reset() {
  echo ">> Deleting exam namespaces..."
  for ns in "${NAMESPACES[@]}"; do
    kubectl delete ns "$ns" --ignore-not-found --wait=false
  done
  echo ">> Reset requested. Namespaces are terminating."
  exit 0
}

if [[ "${1:-}" == "--reset" ]]; then
  reset
fi

echo ">> Creating namespaces..."
for ns in "${NAMESPACES[@]}"; do
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create ns "$ns"
done

# Label the clients namespace for Q15 (namespaceSelector target)
kubectl label ns exam-clients team=clients --overwrite

echo ">> [Q9] Seeding a Pending deployment 'stuck' in exam-health..."
# Pod stays Pending because it requests far more memory than any node has.
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stuck
  namespace: exam-health
  labels:
    app: stuck
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stuck
  template:
    metadata:
      labels:
        app: stuck
    spec:
      containers:
        - name: app
          image: nginx:1.25
          resources:
            requests:
              memory: "300Gi"   # <-- unschedulable on purpose
              cpu: "100m"
YAML

echo ">> [Q14] Seeding 'shop' Deployment + Service + TLS secret in exam-net..."
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: exam-net
  labels:
    app: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
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
  name: shop
  namespace: exam-net
spec:
  selector:
    app: shop
  ports:
    - port: 80
      targetPort: 80
YAML

# Self-signed cert for the Ingress TLS task.
if ! kubectl -n exam-net get secret shop-tls >/dev/null 2>&1; then
  TMP=$(mktemp -d)
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
    -subj "/CN=shop.example.com/O=shop" >/dev/null 2>&1
  kubectl -n exam-net create secret tls shop-tls \
    --cert="$TMP/tls.crt" --key="$TMP/tls.key"
  rm -rf "$TMP"
fi

echo ">> [Q15] Seeding 'web' pod + Service in exam-net and 'caller' in exam-clients..."
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: exam-net
  labels:
    app: web
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
  name: web
  namespace: exam-net
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: caller
  namespace: exam-clients
  labels:
    app: caller
spec:
  containers:
    - name: client
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
YAML

echo
echo ">> Seed complete. Namespaces:"
for ns in "${NAMESPACES[@]}"; do echo "   - $ns"; done
echo
echo ">> Notes:"
echo "   - Q9: deployment/stuck in exam-health is intentionally Pending (fix it)."
echo "   - Q12: you must label a node disktype=ssd yourself."
echo "   - Start your 120-minute timer now. Good luck!"
