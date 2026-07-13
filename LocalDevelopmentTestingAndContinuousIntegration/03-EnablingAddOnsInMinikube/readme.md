# Enabling Add-Ons in minikube

This guide shows how to enable and manage minikube addons for enhanced local development capabilities.

## Overview

minikube includes built-in addons that extend Kubernetes functionality with components like Ingress, metrics collection, and storage provisioning.

## Starting minikube with Resources

```bash
# Start minikube with increased resources
minikube start --cpus=4 --memory=8192 --disk-size=20g
```

## Common Addons

### Ingress Controller
```bash
minikube addons enable ingress
minikube addons status | grep ingress
```

### Metrics Server (for HPA/monitoring)
```bash
minikube addons enable metrics-server
kubectl get pods -n kube-system | grep metrics-server
```

### Dashboard
```bash
minikube addons enable dashboard
minikube dashboard
```

### Storage Provisioner
```bash
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

## Verify Addon Health

```bash
# Check all addon pods
kubectl get pods -n kube-system

# Check specific addon status
minikube addons list
minikube addons status ingress
```

## Disable Addons

```bash
minikube addons disable <addon-name>
```

## Best Practices

1. Enable only addons you need to save resources
2. Wait for addon pods to be ready before testing
3. Check logs if addon pods are not running
4. Restart minikube if addons don't activate properly

```bash
minikube restart
```
