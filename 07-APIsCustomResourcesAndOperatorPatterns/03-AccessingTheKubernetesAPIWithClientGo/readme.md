# Accessing the Kubernetes API with client-go

This lesson explains why direct API access matters and how `client-go` gives Go programs typed access to Kubernetes resources.

## Why Go Beyond kubectl?

`kubectl` is a convenient abstraction over the Kubernetes REST API. Direct API access unlocks:

- deeper automation and integration
- custom tools beyond kubectl defaults
- event-driven workflows and watches
- foundations for operators and controllers

## API Structure

Kubernetes exposes RESTful endpoints grouped by API group and version.

Examples:

- core resources
- `apps`
- `batch`

Resources follow standard CRUD verbs such as `GET`, `POST`, `PUT`, and `DELETE`.

## Authentication and Authorization

API access typically depends on:

- kubeconfig for cluster credentials and context
- TLS for secure transport
- ServiceAccounts for in-cluster identity
- RBAC to control allowed actions

## Why client-go?

`client-go` is the official Go client maintained by the Kubernetes project.

Benefits:

- typed clients for API groups such as `CoreV1` and `AppsV1`
- less manual REST handling
- built-in support for retries, watches, and authentication flows
- good fit for controllers, CLIs, dashboards, and CI/CD integrations

## Basic Flow with client-go

1. Load kubeconfig.
2. Build a REST config.
3. Create a clientset.
4. Call typed methods such as `CoreV1().Pods()`.

Example shape:

```go
pods, err := clientset.CoreV1().Pods("default").List(ctx, metav1.ListOptions{})
for _, pod := range pods.Items {
    fmt.Println(pod.Name)
}
```

## Common Use Cases

- query internals that default kubectl output does not expose clearly
- build automation around pod or workload events
- write dashboards or internal platform tools
- build the foundations of operators and custom controllers

## Key Takeaways

- kubectl is built on the Kubernetes API, not separate from it
- client-go gives you strongly typed access instead of raw REST calls
- direct API access is most useful when you need repeatable automation