# Custom Resource Definitions (CRDs)

This lesson introduces CRDs as Kubernetes extension points that let teams define domain-specific APIs without forking Kubernetes.

## Why CRDs Exist

Native objects such as Pods and Services do not cover every platform use case. CRDs let you extend Kubernetes with resource types that match your domain.

Examples:

- `Database`
- `Backup`
- `Website`

## Core CRD Concepts

A CRD usually involves these pieces:

- `kind`: the new object type you want to create
- API group and version: for namespacing and evolution
- `spec`: the desired state
- `status`: the observed state reported by controllers

## Example Shape

The transcript describes a CRD that defines a new `Database` type under a custom API group and version.

Example YAML:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.mycompany.com
spec:
  group: mycompany.com
  versions:
    - name: v1
      served: true
      storage: true
  scope: Namespaced
  names:
    kind: Database
    plural: databases
    singular: database
```

This manifest is also saved as `database-crd.yaml` in this folder.

Important design choices include:

- grouping under a custom domain such as `mycompany.com`
- versioning with forms like `v1alpha1`, `v1beta1`, or `v1`
- choosing `Namespaced` scope for isolation when appropriate

## Schema and Validation

CRDs use an OpenAPI schema to define:

- field names
- field types
- allowed values and constraints
- optional defaults and cleanup behavior

This helps validate custom resources before they are persisted.

## Version Evolution

- alpha or beta versions are experimental and may change frequently
- `v1` is the stable target for long-term support
- multiple versions can coexist, often with conversion logic during migration

## Real-World Use Cases

- operators that manage databases or other stateful systems
- policy engines such as OPA Gatekeeper
- observability platforms that add custom metrics resources
- CI/CD systems that expose pipelines or rollout abstractions

## Key Takeaways

- CRDs let you extend Kubernetes using its native API model
- schema and versioning matter from the start
- CRDs become far more powerful when paired with controllers or operators