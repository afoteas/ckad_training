# Implementing Rolling Updates with Deployments

This lesson demonstrates Kubernetes rolling updates for zero-downtime deployment changes.

## What Rolling Update Does

A Deployment rolling update gradually replaces old Pods with new Pods after a pod template change, typically an image update.

Benefits:

- minimizes downtime
- keeps service capacity available during update
- supports fast rollback to a previous revision

## Prerequisites

- Kubernetes cluster (kind, minikube, Docker Desktop, or cloud)
- kubectl configured to the target context

## Demo Flow

### 1) Create initial deployment

```bash
kubectl create deployment webserver --image=nginx:1.20.1 --replicas=3
kubectl get deployment webserver
kubectl get pods -l app=webserver
```

### 2) Trigger rolling update

```bash
kubectl set image deployment/webserver nginx=nginx:1.22.1
```

### 3) Monitor rollout

```bash
kubectl rollout status deployment/webserver
```

### 4) Verify ReplicaSets and Pod replacement

```bash
kubectl get pods -l app=webserver
kubectl get rs -l app=webserver
```

### 5) Check rollout history

```bash
kubectl rollout history deployment/webserver
```

## Notes

- Deployment controller creates a new ReplicaSet for the new pod template.
- It scales up new Pods while scaling down old Pods incrementally.
- Default rolling behavior preserves availability during transition.

## Summary

Rolling updates are the default and safest Deployment upgrade path for stateless applications in Kubernetes, offering controlled replacement, observability, and rollback support.
