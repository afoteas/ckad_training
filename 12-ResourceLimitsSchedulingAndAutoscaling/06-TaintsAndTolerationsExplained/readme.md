# Taints and Tolerations Explained

Node affinity attracts Pods to nodes. Taints and tolerations do the opposite: they repel Pods unless explicitly allowed.

A **taint** is applied to a node. The scheduler treats it as a warning: "do not place Pods here unless they explicitly tolerate this taint." A **toleration** is added to a Pod spec to grant that exception.

## Why Use Taints

Use taints to reserve special nodes for specific workloads, such as:

- GPU nodes
- security-sensitive nodes
- infrastructure-only nodes

## Taint Syntax

```text
<key>=<value>:<effect>
```

Example:

```text
dedicated=finance:NoSchedule
```

| Part | Example | Purpose |
|------|---------|---------|
| `key` | `dedicated` | Identifies the taint category |
| `value` | `finance` | Narrows the taint to a specific use case |
| `effect` | `NoSchedule` | Defines how the scheduler reacts |

### Key and Value Are Custom

Unlike some built-in Kubernetes fields, the **key** and **value** are entirely up to you. They are not fixed keywords — you choose names that describe your use case, just like node labels.

Examples:

```bash
kubectl taint nodes node1 gpu=true:NoSchedule
kubectl taint nodes node2 environment=production:NoExecute
kubectl taint nodes node3 dedicated=finance:NoSchedule
```

The toleration on the Pod must match the same key, value, and effect (when using `operator: Equal`).

You can also create a taint with **key and effect only**, with no value:

```bash
kubectl taint nodes node1 special:NoSchedule
```

In that case, the Pod toleration would use `operator: Exists` instead of `Equal`.

### Taint Effects

Kubernetes supports exactly three taint effects. Only the **effect** is predefined — key and value are your choice.

| Effect | Blocks new Pods? | Evicts existing Pods? | Strictness |
|--------|------------------|------------------------|------------|
| `NoSchedule` | Yes | No | Hard |
| `PreferNoSchedule` | No (scheduler avoids if possible) | No | Soft |
| `NoExecute` | Yes | Yes | Hardest |

#### `NoSchedule`

New Pods without a matching toleration are **not scheduled** on the node. Pods already running on the node are **not** evicted.

```bash
kubectl taint nodes <node-name> dedicated=finance:NoSchedule
```

Use for dedicated nodes (GPU, finance, infrastructure) where you want to block new workloads but leave existing ones alone.

#### `PreferNoSchedule`

The scheduler **tries to avoid** placing non-tolerating Pods on the node, but will still schedule them there if no better node is available.

```bash
kubectl taint nodes <node-name> dedicated=finance:PreferNoSchedule
```

Use when you want to discourage general workloads without fully blocking them — a soft preference, not a hard rule.

#### `NoExecute`

New Pods without a matching toleration are **blocked**, and **existing** non-tolerating Pods are **evicted** from the node.

```bash
kubectl taint nodes <node-name> dedicated=finance:NoExecute
```

Use when a node must be strictly isolated, or when you need to remove workloads that should no longer run there (for example during maintenance or node repurposing).

Pods that tolerate the taint can optionally include `tolerationSeconds` to delay eviction:

```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "finance"
  effect: "NoExecute"
  tolerationSeconds: 3600
```

After 3600 seconds, the Pod is evicted even though it tolerates the taint. If `tolerationSeconds` is omitted, the Pod is not evicted by that taint.

## Tolerations

A Pod toleration is an allow-list entry in `spec.tolerations`.

To schedule on a tainted node, the toleration must match key/value/effect as required by taint logic.

### Toleration Matching

The `operator` field in a toleration supports **only two values** — unlike node affinity, which has `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, and `Lt`.

| Operator | Meaning |
|----------|---------|
| `Equal` | Toleration must match the taint's **key**, **value**, and **effect** (default if omitted) |
| `Exists` | Toleration matches any taint with the same **key** and **effect**; **value** is ignored |

#### `operator: Equal`

Use when the toleration must match a specific key **and** value:

```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "finance"
  effect: "NoSchedule"
```

This matches the taint `dedicated=finance:NoSchedule` exactly.

#### `operator: Exists`

Use when only the key matters — the value can be anything. Do **not** set `value` when using `Exists`:

```yaml
tolerations:
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"
```

This matches any taint with key `dedicated`, regardless of value (for example `dedicated=finance:NoSchedule` or `dedicated=hr:NoSchedule`).

`Exists` is also used when the taint has no value:

```bash
kubectl taint nodes node1 special:NoSchedule
```

```yaml
tolerations:
- key: "special"
  operator: "Exists"
  effect: "NoSchedule"
```

If the toleration does not match, the scheduler skips that node.

**CKAD tip:** For tolerations, the answer is almost always `Equal` or `Exists`. Use `Equal` when key + value must match; use `Exists` when only the key matters.

## Taints vs Labels and Affinity

Labels, affinity, and taints all influence scheduling, but they work in opposite directions.

### Labels

A **label** is metadata attached to a node. It does not block or attract Pods by itself — it is just a tag.

```bash
kubectl label nodes <node-name> disktype=ssd
```

Labels become useful when a Pod references them through `nodeSelector` or `nodeAffinity`.

### Node Selector and Affinity (Pod pulls toward nodes)

`nodeSelector` and `nodeAffinity` are rules defined **on the Pod**. They tell the scheduler where the Pod **wants** to run.

```yaml
nodeSelector:
  disktype: ssd
```

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disktype
          operator: In
          values: [ssd]
```

- The Pod actively **seeks** nodes with matching labels.
- If no matching node exists, the Pod stays `Pending`.
- Pods without these rules can still schedule on labeled nodes if capacity is available.

### Taints and Tolerations (Node pushes Pods away)

A **taint** is applied **on the node**. It tells the scheduler to **reject** Pods unless they have a matching toleration.

```bash
kubectl taint nodes <node-name> dedicated=finance:NoSchedule
```

```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "finance"
  effect: "NoSchedule"
```

- The node actively **blocks** Pods that do not tolerate the taint.
- A toleration is an explicit allow-list entry on the Pod.
- Without a toleration, the Pod cannot schedule on that node — even if it has free resources.

### Side-by-Side Comparison

| | **Labels + affinity/nodeSelector** | **Taints + tolerations** |
|---|---|---|
| Applied on | Node (label) + Pod (rule) | Node (taint) + Pod (toleration) |
| Direction | Pod **pulls toward** matching nodes | Node **pushes away** non-matching Pods |
| Default behavior | Any Pod can land on a labeled node | No Pod can land on a tainted node unless it tolerates |
| Best for | "I need a node with SSD / GPU / zone X" | "Keep general workloads off this special node" |
| CKAD mental model | Attraction | Repulsion |

### When to Use Which

Use **labels and affinity** when the workload knows what it needs:

> "Schedule me only on nodes with `disktype=ssd`."

Use **taints and tolerations** when the node must be protected:

> "This node is reserved for finance workloads — block everything else."

### Using Them Together

In production, special nodes often use both:

1. **Label** the node so intended workloads can find it:
   ```bash
   kubectl label nodes <node-name> workload=finance
   ```
2. **Taint** the node so random Pods are blocked:
   ```bash
   kubectl taint nodes <node-name> dedicated=finance:NoSchedule
   ```
3. On the finance Pod, add **affinity** (to prefer the right node) and a **toleration** (to be allowed on the tainted node):
   ```yaml
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         - matchExpressions:
           - key: workload
             operator: In
             values: [finance]
   tolerations:
   - key: "dedicated"
     operator: "Equal"
     value: "finance"
     effect: "NoSchedule"
   ```

- **Affinity** = put the right Pod on the right node.
- **Taint** = keep every other Pod off that node.

## Operational Value

- Protect expensive hardware from general workloads.
- Isolate critical or system-level services.
- Enforce environment boundaries in shared clusters.

## Key Takeaway

Taints define node restrictions; tolerations grant workload exceptions.

In practice, taints are often combined with labels and node selectors or affinity rules: taints keep general workloads off special nodes, while tolerations allow only the intended Pods to run there.
