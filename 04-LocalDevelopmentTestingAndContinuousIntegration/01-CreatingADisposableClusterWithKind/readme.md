# Creating a Disposable Cluster with kind

This guide demonstrates how to set up a temporary Kubernetes cluster using kind (Kubernetes in Docker) for local development and testing.

## Overview

kind allows you to run Kubernetes clusters using Docker container nodes. It's ideal for:
- Local development and testing
- CI/CD pipelines
- Quick cluster spin-up and tear-down

## Quick Start

### Install kind and kubectl
```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version
```

### Create a Cluster
```bash
kind create cluster --name ckad-dev
```

### Verify the Cluster
```bash
kubectl cluster-info --context kind-ckad-dev
kubectl get nodes
```

### Delete the Cluster
```bash
kind delete cluster --name ckad-dev
```

## Multi-Node Configuration

The `kind-multi-node-config.yaml` file demonstrates a multi-node cluster setup with:
- 1 control-plane node with port mapping for NodePort services
- 3 worker nodes with zone labels for testing affinity rules

### Create Multi-Node Cluster
```bash
kind create cluster --config kind-multi-node-config.yaml --name multi-node
```

## Key Benefits

- **Fast**: Clusters start in seconds
- **Lightweight**: Runs in Docker containers
- **Portable**: Works on Linux, macOS, and Windows (with Docker)
- **Clean**: Easy cluster cleanup without VM overhead

## CKAD Note

`kind` is developer/CI tooling and is **not** part of the CKAD exam — the exam gives you a ready cluster that you drive entirely through `kubectl`.

- No exam task asks you to run `kind create cluster` or author a `kind-multi-node-config.yaml`.
- What *is* examinable are the objects you create inside a cluster: Pods, Deployments, Services, and `NodePort` access (the reason for the control-plane port mapping here).
- The worker-node zone labels used here matter on the exam only through `nodeSelector`, node affinity, and topology spread constraints on Pods.

## Key Takeaway

`kind` gives you a fast, disposable, Docker-based Kubernetes cluster for local practice and CI, but on the CKAD exam it stays invisible — you only need to be fluent with `kubectl` against whatever cluster is provided.
