# Creating Pods Programmatically in Go

This lesson walks through a small Go program that connects to Kubernetes, creates resources, and lists pods with useful metadata.

## Why Use the Go Client?

The official Go client library, `client-go`, is useful for:

- automation
- custom controllers
- operators
- CLI tools
- monitoring applications

## Prerequisites

- Go installed locally
- a running Kubernetes cluster
- kubectl already configured for that cluster

## Initialize the Project

Create a Go module:

```bash
go mod init k8s-go-client-demo
```

Install the required Kubernetes libraries:

```bash
go get k8s.io/client-go@latest
go get k8s.io/api@latest
go get k8s.io/apimachinery@latest
```

## Program Flow

The example program does the following:

1. Builds the kubeconfig path.
2. Connects to the cluster.
3. Creates a namespace named `go-demo`.
4. Creates an Nginx pod.
5. Creates a Redis pod.
6. Waits briefly for scheduling.
7. Lists pods in the namespace.
8. Filters by label when needed.
9. Retrieves detailed information for a specific pod.

## What the Program Can Print

For each pod, the walkthrough highlights these fields:

- pod name
- status
- node name
- pod IP
- labels
- containers in use

## Key Ideas

- Kubernetes actions in Go map to the same API concepts used by kubectl
- typed clients make object creation and listing safer than raw REST calls
- once connected, you can create, filter, and inspect resources programmatically

## Typical Next Steps

After basic pod creation and listing, the same pattern can be extended to:

- create Deployments and Services
- react to watch events
- build reconciliation logic
- power internal automation tools

## CKAD Note

- Creating Pods programmatically in Go with `client-go` is **outside CKAD scope** — the exam expects you to create workloads with `kubectl` and YAML, not code.
- The equivalent examinable skills are imperative creation (`kubectl run nginx --image=nginx`, `kubectl create deployment`) and `kubectl run/create ... --dry-run=client -o yaml` to scaffold manifests fast.
- Namespaces, labels, and pod fields (`status`, `podIP`, `nodeName`, containers) shown here map to what you inspect via `kubectl get -o wide` / `-o yaml`.
- Treat the Go program as background for how operators/controllers work; nothing here requires Go on the exam.

## Key Takeaway

Programmatic pod management demonstrates that every Kubernetes action maps to the same API objects you already manage with `kubectl` — for CKAD, reproduce these operations imperatively and with YAML rather than in Go.