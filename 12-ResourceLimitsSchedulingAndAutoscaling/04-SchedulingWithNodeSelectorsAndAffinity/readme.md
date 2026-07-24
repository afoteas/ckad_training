# Scheduling with Node Selectors and Affinity

Kubernetes can place Pods automatically, but some workloads need placement constraints for hardware, security, or environment segregation.

## Node Selector

`nodeSelector` is the simplest hard constraint.

- Pod schedules only on nodes with exact matching label key/value.
- If no node matches, Pod remains `Pending`.

### Example Pod with NodeSelector

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-ssd
spec:
  containers:
    - name: nginx
      image: nginx
  nodeSelector:
    disktype: ssd
```

This Pod will only schedule on nodes labeled with `disktype: ssd`. If no such node exists, the Pod stays `Pending`.

**To label a node:**
```bash
kubectl label nodes <node-name> disktype=ssd
```

## Node Affinity

`nodeAffinity` is more expressive than `nodeSelector`.

- Supports operators such as `In`, `NotIn`, and `Exists`.
- Supports hard rules (`requiredDuringSchedulingIgnoredDuringExecution`).
- Supports soft preferences (`preferredDuringSchedulingIgnoredDuringExecution`).

### Example Pod with Node Affinity (Hard Constraint)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-demo
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
  containers:
    - name: nginx
      image: nginx
```

This Pod requires a node with label `disktype` having value `ssd`. The `In` operator allows multiple acceptable values (useful for flexibility).

**Other operators:**
- `In` — value must be in the list
- `NotIn` — value must NOT be in the list
- `Exists` — key exists (values ignored)
- `DoesNotExist` — key does not exist
- `Gt` — value greater than
- `Lt` — value less than

### Equivalent: Node Affinity Matching nodeSelector

`nodeAffinity` with `requiredDuringSchedulingIgnoredDuringExecution` and operator `In` can replicate simple `nodeSelector` behavior:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: affinity-equivalent
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                  - ssd
  containers:
    - name: nginx
      image: nginx
```

This is functionally identical to the `nodeSelector: disktype: ssd` example above — both require a node with `disktype=ssd` label.

## Labeling Nodes

Before using `nodeSelector` or `nodeAffinity`, you need to label your nodes.

### Via kubectl (Imperative)

**Label a single node:**
```bash
kubectl label nodes node1 disktype=ssd
kubectl label nodes node2 disktype=hdd performance=low
```

**View node labels:**
```bash
kubectl get nodes --show-labels
kubectl get nodes -L disktype,performance    # show specific label columns
```

**Remove or update labels:**
```bash
kubectl label nodes node1 disktype=nvme --overwrite
kubectl label nodes node1 disktype-          # remove label (trailing dash)
```

### Via Kind (Declarative)

Define labels when creating a Kind cluster:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    labels:
      node-type: control
      
  - role: worker
    labels:
      disktype: ssd
      performance: high
      
  - role: worker
    labels:
      disktype: hdd
      performance: low
```

Create cluster with config:
```bash
kind create cluster --config cluster-config.yaml --name my-cluster
```

**Note:** Kind lets you define labels at cluster creation time, but Minikube requires post-creation labeling with `kubectl label`.

## Hard vs Soft Matching

- Hard: must match, or Pod is unscheduled.
- Soft: scheduler tries to match, but may place elsewhere if needed.

## Common Use Cases

- GPU workloads on labeled GPU nodes.
- SSD-bound workloads on low-latency storage nodes.
- Environment isolation with labels like `environment=prod` and `environment=dev`.
- Compliance workloads pinned to hardened nodes.

## Other Affinity Types: podAffinity and podAntiAffinity

Beyond `nodeAffinity`, Kubernetes supports Pod-to-Pod affinity:

### podAffinity (Co-locate Pods)

Schedule a Pod on the **same node/zone** as another Pod:

```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - database
        topologyKey: kubernetes.io/hostname
```

**Use case:** Keep frontend + database on same node for low latency.

### podAntiAffinity (Spread Pods)

Schedule a Pod **away from** other Pods:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - web
        topologyKey: kubernetes.io/hostname
```

**Use case:** Spread replicas across nodes for high availability.

### Topology Key Scopes

- `kubernetes.io/hostname` — different nodes
- `topology.kubernetes.io/zone` — different availability zones
- `topology.kubernetes.io/region` — different regions

**Note:** podAffinity/podAntiAffinity are less common in CKAD. Focus on `nodeAffinity` first.

## CKAD Tips

- Label nodes imperatively: `kubectl label nodes <node> disktype=ssd`; remove with a trailing dash: `kubectl label nodes <node> disktype-`.
- Inspect targets with `kubectl get nodes --show-labels` (or `-L disktype,performance`).
- `nodeSelector` is exact-match only; use `nodeAffinity` for operators (`In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt`).
- Memorize the long field names: `requiredDuringSchedulingIgnoredDuringExecution` (hard) vs `preferredDuringSchedulingIgnoredDuringExecution` (soft, weighted 1–100).
- An unsatisfiable hard rule leaves the Pod `Pending` — `kubectl describe pod` Events explain the mismatch.

## Key Takeaway

Use `nodeSelector` for simple mandatory placement and `nodeAffinity` for flexible, production-grade scheduling logic. Use `podAffinity`/`podAntiAffinity` for Pod-to-Pod relationships.
