# Installing kube-prometheus-stack via Helm

This demo installs the complete kube-prometheus-stack onto a Kubernetes cluster using Helm, then verifies Prometheus is scraping metrics and Grafana is accessible.

## Install

```bash
# Add the Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update to pull the latest chart metadata
helm repo update

# Install the stack into a dedicated namespace
helm install monitoring prometheus-community/kube-prometheus-stack \
  --create-namespace --namespace monitoring
```

The `--create-namespace` flag creates the `monitoring` namespace automatically.

## Verify Pods

```bash
kubectl get pods --namespace monitoring
```

Wait until all pods reach `Running` state. Some exporters require a Linux node; on Windows-based dev environments, certain pods may not start — this does not block the demo.

## Verify Prometheus (Target Health)

```bash
# Expose Prometheus locally
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 --namespace monitoring
```

Open `http://localhost:9090` → **Status** → **Target Health** to confirm scrape targets are active.

## Verify Grafana

```bash
# Retrieve the admin password (base64 decoded)
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Expose Grafana locally
kubectl port-forward svc/monitoring-grafana 3000:80 --namespace monitoring
```

Open `http://localhost:3000`, log in with username `admin` and the decoded password.

Navigate to **Dashboards → Kubernetes / Compute Resources / Cluster** to confirm metrics are flowing.

## CKAD Note

Installing the monitoring stack with Helm is real-world tooling and is **not** examinable — Helm itself is not on the CKAD exam. The transferable, in-scope skills here are the plain `kubectl` verbs used to verify the install.

- `kubectl get pods -n monitoring` to check rollout status and `kubectl port-forward svc/... 9090:9090 -n monitoring` to reach a service locally are both examinable techniques.
- Decoding a Secret with `kubectl get secret ... -o jsonpath="{.data.admin-password}" | base64 --decode` is a genuine CKAD pattern — practice it independently of Grafana.

## Key Takeaway

Helm bundles the whole Prometheus/Grafana stack into one release, but for CKAD what matters is the underlying `kubectl` workflow — verifying pods, port-forwarding to services, and reading Secrets — not the Helm chart itself.
