# Scaffolding an Operator with Kubebuilder

This lesson covers the scaffolding workflow for a new operator project. The transcript demo uses Operator SDK commands, but the overall workflow applies to operator scaffolding in general.

## Prerequisites

- Go installed
- Docker installed
- kubectl installed and connected to a cluster
- an operator scaffolding tool installed locally

The transcript uses Operator SDK installation with Homebrew (macOS):

```bash
brew install operator-sdk
operator-sdk version
```

For Linux, install Operator SDK from the GitHub release binary:

```bash
curl -LO "https://github.com/operator-framework/operator-sdk/releases/download/v1.42.3/operator-sdk_linux_amd64"
chmod +x "operator-sdk_linux_amd64"
sudo mv "operator-sdk_linux_amd64" /usr/local/bin/operator-sdk
operator-sdk version
```

## Initialize the Project

The walkthrough initializes a new operator project with a custom domain and repository:

```bash
operator-sdk init --domain example.com --repo github.com/example/guestbook-operator
```

This creates:

- a Go module
- project structure
- Makefile
- Dockerfile
- config manifests

## Create a Custom API

The transcript then generates an API and controller scaffold:

```bash
operator-sdk create api --group webapp --version v1 --kind Guestbook --resource --controller
```

This creates files such as:

- `api/v1/guestbook_types.go`
- controller code for `Guestbook`
- CRD manifest scaffolding

## Define Spec and Status

The generated `guestbook_types.go` file is then extended with fields such as:

- desired state fields like size, image, and port
- observed state fields like replicas, ready replicas, and conditions
- validation markers and defaults
- custom printer columns for easier kubectl output

## Implement Reconcile Logic

The controller reconcile loop is responsible for:

- fetching the custom resource
- creating a Deployment with the requested image and replica count
- creating a Service to expose the workload
- updating status fields
- reacting to spec changes over time

## Generate and Test Artifacts

The transcript uses:

```bash
make manifests
make generate
```

These steps generate:

- CRD YAML from code annotations
- RBAC manifests from controller annotations
- boilerplate helper code such as deep-copy methods

For local development, the workflow then installs the CRD and runs the controller process for debugging.

## CKAD Note

- Kubebuilder/Operator SDK scaffolding, `make manifests`/`make generate`, and writing `_types.go` and reconcile code are **well beyond CKAD scope** — no operator development is tested.
- The only exam-relevant residue is the output: generated CRD YAML and RBAC manifests are ordinary objects you apply and inspect with `kubectl apply -f` and `kubectl get crds`.
- Spec vs status as the "contract" mirrors the `.spec`/`.status` split you already work with on native resources.
- Skip the tooling install steps for exam prep; concentrate on managing the resulting resources declaratively.

## Key Takeaway

- scaffolding saves time by generating the standard controller project layout
- spec and status types define the contract for your operator
- reconcile logic is where the real domain behavior lives