# Local Development, Testing, and Continuous Integration

This chapter covers practical workflows for local Kubernetes development, integration testing, and CI pipeline validation.

## 1. Creating a Disposable Cluster with kind

Small guide:
- Install kind and kubectl.
- Create a short-lived cluster for local testing:
  ```bash
  kind create cluster --name ckad-dev
  kubectl cluster-info --context kind-ckad-dev
  ```
- Delete it when done to keep your machine clean:
  ```bash
  kind delete cluster --name ckad-dev
  ```

## 2. Choose the Right Local Cluster in Minikube and Kind

Small guide:
- Use kind for fast, container-based CI-like clusters.
- Use minikube when you need built-in addons or VM-style isolation.
- Pick one default context and verify before applying manifests:
  ```bash
  kubectl config current-context
  kubectl get nodes
  ```

## 3. Enabling Add-Ons in minikube

Small guide:
- Start minikube with enough resources.
- Enable only the addons you need (example: ingress, metrics-server):
  ```bash
  minikube start
  minikube addons enable ingress
  minikube addons enable metrics-server
  ```
- Confirm addon-related pods are healthy in kube-system.

## 4. Live Coding with Skaffold Dev Loop

Small guide:
- Initialize a skaffold config for your app.
- Run continuous build/deploy/log loop:
  ```bash
  skaffold dev
  ```
- Edit code and watch automatic rebuild and redeploy feedback.

## 5. Configuring Skaffold Hot-Reload with Kaniko Build

Small guide:
- Configure skaffold to use Kaniko builder for in-cluster image builds.
- Enable file sync rules to avoid full image rebuilds for simple changes.
- Use profiles for local vs CI behavior, then run:
  ```bash
  skaffold dev -p local
  ```

## 6. Tilt for Local Microservice Stacks

Small guide:
- Create a Tiltfile that loads all microservices.
- Define resources so each service can build, deploy, and stream logs.
- Start the local platform view:
  ```bash
  tilt up
  ```

## 7. Performing Multi-Service Dev with Tilt and Live Updates

Small guide:
- Add live_update rules in the Tiltfile for fast in-container sync.
- Group related services and set explicit dependencies.
- Use the Tilt UI to restart only impacted services instead of full stack redeploys.

## 8. Integration Test Writing with kube-test-harness

Small guide:
- Build tests around real Kubernetes behavior, not only unit mocks.
- Spin up required test fixtures (namespaces, secrets, configmaps) per test suite.
- Ensure each test is isolated and tears down all created resources.

## 9. Running Go Integration Tests Against kind in CI

Small guide:
- In CI, create a kind cluster as a first test stage.
- Build and load your image into kind before running tests.
- Run integration tests with clear tags/timeouts:
  ```bash
  go test ./... -tags=integration -v
  ```

## 10. Helm Chart Testing and Linting

Small guide:
- Lint chart structure and values early:
  ```bash
  helm lint ./chart
  ```
- Template manifests and validate rendered output.
- Add chart tests to verify key resources and expected defaults.

## 11. Building Images, Linting Helm, and Deploying to kind in the CI Pipeline

Small guide:
- Order pipeline steps as: build image -> lint/test chart -> deploy -> validate.
- Fail fast on linting and manifest errors before deployment.
- After deploy, run smoke checks:
  ```bash
  kubectl get pods -A
  kubectl rollout status deploy/<app-name>
  ```

## 12. Cleanup and Resource Optimization in CI Clusters

Small guide:
- Always delete ephemeral namespaces or full clusters after tests.
- Reuse cached dependencies/layers to reduce CI runtime.
- Set resource requests/limits in test workloads to avoid noisy-neighbor failures.


## Objectives

- spin up a multi‑node cluster using Docker‑in‑Docker
- differentiate between runtime drivers, add‑ons, and their performance trade‑offs
- turn on Ingress and metrics-server add‑ons for local dev
- describe how to auto‑build, push, and deploy changes on file save
- configure Skaffold to build via Kaniko and deploy to kind
- outline Tiltfile syntax, live updates, and the UI
- orchestrate two services with instant container sync
- identify how to generate test clusters, apply manifests, assert resource states
- use GitHub Actions to start kind, run go test, and export JUnit
- describe how to use the helm test chart testing tool to catch issues early
- combine buildx, helm‑lint, and kubectl apply in GitHub Actions
- outline how to automate cluster teardown and cache layers to reduce job time