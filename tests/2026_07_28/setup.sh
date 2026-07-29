#!/usr/bin/env bash
# Setup for the 2026-07-28 CKAD practice exam.
# Creates all exam namespaces and the pre-existing objects that dependent / "fix it" tasks need.
#
#   bash setup.sh            # create namespaces + seed objects
#   bash setup.sh --reset    # delete exam namespaces first, then recreate
set -euo pipefail

NAMESPACES=(
  app-deploy
  app-config
  app-secure
  app-health
  app-batch
  app-design
  app-net
  app-ingress
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

echo ">> Q7: seeding resource-app in app-secure (student sets requests/limits)..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-app
  namespace: app-secure
  labels:
    app: resource-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resource-app
  template:
    metadata:
      labels:
        app: resource-app
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF

echo ">> Q9: seeding crashy in app-health (CrashLoopBackOff — student must fix)..."
# Broken on purpose: the command is a typo ('sleeep') so the container exits
# immediately and, with restartPolicy Always (Deployment default), CrashLoopBackOffs.
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crashy
  namespace: app-health
  labels:
    app: crashy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: crashy
  template:
    metadata:
      labels:
        app: crashy
    spec:
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "sleeep 3600"]
EOF

echo ">> Q13: seeding api pods (label app=api) in app-net..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: app-net
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF

echo ">> Q14: seeding site Deployment + Service in app-ingress..."
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: site
  namespace: app-ingress
  labels:
    app: site
spec:
  replicas: 1
  selector:
    matchLabels:
      app: site
  template:
    metadata:
      labels:
        app: site
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
  name: site
  namespace: app-ingress
spec:
  selector:
    app: site
  ports:
  - port: 80
    targetPort: 80
EOF

echo ">> Q15: seeding frontend + db pods and db Service in app-net..."
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: app-net
  labels:
    app: frontend
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: app-net
  labels:
    app: db
spec:
  containers:
  - name: db
    image: nginx:1.25
    ports:
    - containerPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: app-net
spec:
  selector:
    app: db
  ports:
  - port: 3306
    targetPort: 3306
EOF

echo ""
echo ">> Setup complete. Exam namespaces:"
kubectl get ns | grep -E 'app-(deploy|config|secure|health|batch|design|net|ingress)' || true
echo ""
echo ">> Q9 seed (should look unhealthy):"
kubectl get deploy crashy -n app-health 2>/dev/null || true
echo ""
echo "Start your timer. Good luck!"
