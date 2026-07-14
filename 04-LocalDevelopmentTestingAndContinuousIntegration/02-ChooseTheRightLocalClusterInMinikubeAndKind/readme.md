# Choose the Right Local Cluster: Minikube and kind

This guide shows a full WSL2-only setup (no Docker Desktop) so you can run both kind and minikube and manage both from kubectl contexts.


## Comparison

| Feature | kind | minikube |
|---------|------|----------|
| **Startup Time** | Very fast (seconds) | Slower (minutes) |
| **Resource Usage** | Lightweight (Docker) | Heavier (VMs) |
| **Addons** | Minimal | Many built-in addons |
| **Best For** | CI/CD, quick testing | Full dev environment |
| **Networking** | Container-based | VM-based |
| **Node Count** | Easy multi-node | Can be multi-node |

## When to Use kind

- Running integration tests in CI pipelines
- Rapid cluster creation and teardown
- Testing multi-node scenarios quickly
- Container-first development workflow

## When to Use minikube

- Need ingress controller out-of-the-box
- Want metrics-server for HPA testing
- Prefer VM isolation
- Need stable, feature-rich local environment


## Goal

- Install a container runtime directly in WSL2
- Install kubectl, kind, and minikube in WSL2
- Create one kind cluster and one minikube cluster
- Use kubectl contexts to switch safely between them

## 0) Prerequisites

- Windows 11 with WSL2 enabled
- Ubuntu distro in WSL2 (or similar Debian-based distro)
- At least 4 vCPU and 8 GB RAM available for WSL

Check WSL from Windows PowerShell:

```powershell
wsl --status
wsl -l -v
```

Inside WSL, verify systemd (recommended for running Docker daemon cleanly):

```bash
ps -p 1 -o comm=
```

If this does not return systemd, enable it in /etc/wsl.conf:

```ini
[boot]
systemd=true
```

Then restart WSL from Windows PowerShell:

```powershell
wsl --shutdown
```

## 1) Install Docker Engine in WSL (No Docker Desktop)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
	$(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker

sudo systemctl enable docker
sudo systemctl start docker
docker version
docker info
```

If docker info fails after group changes, open a new WSL shell and rerun docker version.

## 2) Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

kubectl version --client
```

## 3) Install kind

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
```

## 4) Install minikube

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

minikube version
```

## 5) Create Both Clusters

Create kind cluster:

```bash
kind create cluster --name ckad
kubectl cluster-info --context kind-ckad
kubectl get nodes --context kind-ckad
```

Note: kind context format is always kind-<cluster-name>. If your cluster name changes, update the context value accordingly.

Create minikube cluster (Docker driver):

```bash
minikube start -p mini-ckad --driver=docker --cpus=2 --memory=4096
kubectl cluster-info --context mini-ckad
kubectl get nodes --context mini-ckad
```

If you are unsure about the exact context names, list them first:

```bash
kubectl config get-contexts
```

## 6) See Both in kubectl and Switch Contexts

List contexts:

```bash
kubectl config get-contexts
```

Switch to kind:

```bash
kubectl config use-context kind-ckad
kubectl config current-context
kubectl get nodes
```

Switch to minikube:

```bash
kubectl config use-context mini-ckad
kubectl config current-context
kubectl get nodes
```

Recommended safety check before every apply:

```bash
kubectl config current-context
kubectl get ns
```

## 7) Minikube Addons for CKAD Practice

```bash
kubectl config use-context ckad-mini

minikube addons enable ingress -p ckad-mini
minikube addons enable metrics-server -p ckad-mini

kubectl get pods -n ingress-nginx
kubectl top nodes
kubectl top pods -A
```

## 8) Cleanup

Delete clusters when finished:

```bash
kind delete cluster --name ckad-kind
minikube delete -p ckad-mini
```

Optional: remove stale contexts if needed:

```bash
kubectl config get-contexts
kubectl config delete-context kind-ckad-kind
kubectl config delete-context ckad-mini
```

## kind vs minikube in This Setup

- Use kind for fast, disposable, CI-like clusters and multi-node experiments.
- Use minikube when you want easy addons such as ingress and metrics-server.
- Keep both installed: choose by context based on each lab objective.
