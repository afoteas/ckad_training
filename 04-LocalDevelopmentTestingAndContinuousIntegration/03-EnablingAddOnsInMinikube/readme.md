# Enabling Ingress and Metrics Server (minikube and kind)

This guide covers both local-cluster paths for the same goal:

- Ingress NGINX for HTTP routing
- Metrics Server for CPU and memory metrics

## Why These Components Matter

Ingress routes external HTTP/HTTPS requests to Services using host and path rules.

Metrics Server collects resource metrics from kubelets and enables:

- kubectl top nodes
- kubectl top pods
- HPA metric input

## Quick Difference: minikube vs kind

- minikube: built-in addon commands
- kind: install the same components via manifests

Both are valid for local Kubernetes practice.

## A) minikube Workflow

### 1) Start or select your minikube profile

```bash
minikube start -p mini-ckad --driver=docker --cpus=2 --memory=4096
kubectl config use-context mini-ckad
```

### 2) Enable Ingress and Metrics Server addons

```bash
minikube addons enable ingress -p mini-ckad
minikube addons enable metrics-server -p mini-ckad
```

### 3) Verify readiness

```bash
kubectl get pods -n ingress-nginx
kubectl get pods -n kube-system | grep metrics-server
kubectl top nodes
kubectl top pods -A
```

## B) kind Workflow

### 1) Create a kind cluster with ingress-friendly port mappings

Use the provided file: `kind-ingress-config.yaml`

Create and select context:

```bash
kind create cluster --name local-dev --config kind-ingress-config.yaml
kubectl config use-context kind-local-dev
kubectl get nodes
```

### 2) Install Ingress NGINX (kind provider manifest)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

Wait for controller readiness:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

### 3) Install Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Patch for common kind self-signed kubelet cert behavior:

```bash
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

Validate metrics:

```bash
kubectl top nodes
kubectl top pods -A
```

## C) Sample Ingress Test

Apply the provided sample manifest file: `ingress-app.yaml`

```bash
kubectl apply -f ingress-app.yaml
kubectl get ingress
kubectl get svc
```

For minikube, test through the minikube node IP:

```bash
curl http://$(minikube ip -p mini-ckad)/hello
```

For kind, use port-forward if localhost path testing does not respond immediately:

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

Then from another terminal:

```bash
curl http://localhost:8080/hello
```

## D) Validation Checklist

```bash
kubectl config current-context
kubectl get pods -n ingress-nginx
kubectl get pods -n kube-system | grep metrics-server
kubectl top nodes
kubectl top pods -A
kubectl describe ingress
```

## E) Access from Windows Host (when running cluster in WSL)

In many WSL2 setups, the minikube node IP is reachable inside WSL but not directly from Windows routing.

### 1) Validate from WSL first

```bash
minikube ip -p mini-ckad
curl http://$(minikube ip -p mini-ckad)/hello
```

### 2) Get a reachable URL via minikube service helper

```bash
minikube service hello-ingress --url -p mini-ckad
```

Open the printed URL from Windows browser.

### 3) Optional fallback: explicit port-forward

```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 --address 0.0.0.0
```

Then open:

```text
http://localhost:8080/hello
```

### 4) Optional LoadBalancer-style test

```bash
minikube tunnel -p mini-ckad
kubectl get svc
```

Use the external IP shown for LoadBalancer services.

## Troubleshooting

- Metrics API not available:
  - wait 30 to 90 seconds
  - check metrics-server pod status and logs
- Empty reply from Ingress route:
  - ensure ingress controller pod is Ready
  - on kind, use the port-forward command above
- Wrong cluster behavior:
  - verify context before every test: kubectl config current-context

## CKAD Tips

- Ingress **is** examinable: know how to create an `Ingress` with host/path rules and the correct `pathType`, and remember it needs both a running ingress controller and a backing `Service`.
- Metrics Server powers `kubectl top nodes` / `kubectl top pods` and feeds HPA — metrics take ~30–90s to appear after install, so don't assume failure too early.
- On kind you usually need the `--kubelet-insecure-tls` arg patched onto `metrics-server`; on minikube it's just `minikube addons enable metrics-server`.
- Debug routing with `kubectl get ingress` and `kubectl describe ingress`, and confirm the rule's `Service` name/port actually match an existing Service.
- The addon/manifest install steps are setup only — the exam tests the `Ingress` and `Service` objects you write, not how the controller got installed.

## Key Takeaway

Ingress and Metrics Server are supported in both minikube and kind.

- minikube: easiest path via addons
- kind: explicit manifest-based install, often closer to production-style setup steps
