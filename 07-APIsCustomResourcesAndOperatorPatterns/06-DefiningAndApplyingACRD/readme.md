# Defining & Applying a CRD

This lesson walks through creating a CRD, registering it with the cluster, and then creating custom resource instances that kubectl can manage like native objects.

## What the Example Builds

The walkthrough defines a new `Application` resource type that models an app with fields such as:

- `appName`
- `replicas`
- `image`
- `port`
- `environment`

## CRD Design Highlights

The example CRD uses:

- a name in the form `applications.demo.example.com`
- API group `demo.example.com`
- version `v1`
- namespaced scope
- short name `app` for easier CLI use

## Schema and Validation Examples

The transcript calls out several schema rules:

- `replicas` is an integer with minimum and maximum constraints
- `environment` is an enum with allowed values like `dev`, `staging`, and `prod`
- required fields include `appName`, `replicas`, and `image`
- status fields track observed state such as current state and last update time

## Apply the CRD

```bash
kubectl apply -f crd-application.yaml
```

Verify that it exists:

```bash
kubectl get crds
kubectl describe crd applications.demo.example.com
kubectl api-resources | grep application
```

## Create Custom Resource Instances

Once the CRD is installed, you can create instances such as an Nginx application or a Redis application.

The key benefit is that your manifest becomes shorter and more domain-focused because the CRD already defines the structure and validation rules.

## Why This Helps

- kubectl now recognizes your new resource type
- teams can express intent with business-level objects instead of low-level primitives
- repeated application definitions become simpler and more consistent

## Key Takeaways

- a CRD by itself registers a new type; it does not deploy workloads automatically
- custom resource instances become first-class Kubernetes objects once the CRD is installed
- validation rules make your custom API safer and easier to use