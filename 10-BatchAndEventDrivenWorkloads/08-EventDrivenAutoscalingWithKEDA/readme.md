# Event-Driven Autoscaling with KEDA

KEDA (Kubernetes Event-Driven Autoscaling) enables scaling based on external event sources, not just CPU and memory.

## The Gap: HPA vs KEDA

The native Horizontal Pod Autoscaler (HPA) scales on cluster-internal metrics (CPU, memory). It reacts **after** work has already started hitting running pods, leading to latency.

KEDA scales on **external event metrics** proactively, spinning up pods the moment the event volume increases.

## Key KEDA Capabilities

- **external metrics**: monitor queue depth (RabbitMQ, Kafka, SQS), stream lag, S3 bucket size, etc.
- **scale-to-zero**: scale deployment down to 0 replicas when no events are pending; instantly scale back up
- **avoids idle pods**: no pods sitting idle consuming resources waiting for events
- **faster reaction**: responds to the metric that precedes work, not the work itself

## KEDA Architecture

```
External Event Source (queue, stream, bucket, API)
            ↑
            │ metrics
            ↓
    KEDA ScaledObject/ScaledJob
            ↓
      Kubernetes HPA
            ↓
     Target Deployment/Job
            (scales 0 → N based on event volume)
```

KEDA acts as a metrics provider, feeding custom metrics to the native HPA.

## Core KEDA Resources

| Resource | Purpose |
|---|---|
| `ScaledObject` | Scale a **Deployment** based on external event metrics |
| `ScaledJob` | Create and run a **Job** based on external event volume |
| `TriggerAuthentication` | Securely reference Kubernetes Secrets for external service credentials |

## ScaledObject Example (RabbitMQ Queue)

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: queue-worker
spec:
  scaleTargetRef:
    name: worker-app          # scale this Deployment
  triggers:
    - type: rabbitmq
      metadata:
        host: rabbitmq.default:5672
        queueName: jobs       # monitor this queue
        mode: QueueLength
      authenticationRef:
        name: rabbitmq-auth   # reference TriggerAuthentication
```

When the `jobs` queue has messages, KEDA scales `worker-app` up. When queue empties, scales to 0.

## TriggerAuthentication Example

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: rabbitmq-auth
spec:
  secretTargetRef:
    - parameter: host
      name: rabbitmq-secret
      key: connection-string
```

Keeps credentials secure; ScaledObject references it by name.

## Ideal Use Cases

- **message queue consumers**: scale pods based on queue depth (RabbitMQ, Kafka, SQS, Azure Service Bus)
- **stream processing**: scale workers based on stream lag
- **IoT/sensor data**: scale on incoming data rate
- **batch jobs**: use ScaledJob to create Jobs on-demand when queue fills
- **periodic tasks**: use cron trigger to run Jobs at specific times, optionally checking for events
- **cost optimization**: scale to 0 during off-hours or when idle

## KEDA vs CronJob

| Feature | CronJob | KEDA |
|---|---|---|
| Scheduling | Time-based (cron syntax) | Event-based (queue depth, stream lag, etc.) |
| Scale-to-zero | No (unless you manually suspend) | Yes (auto-scales to 0 when idle) |
| External integration | Manual | Native (RabbitMQ, Kafka, S3, etc.) |
| Ideal for | Recurring scheduled tasks | Event-driven workloads with variable load |

## Installation

Install KEDA using Helm or kubectl apply:

```bash
# Using Helm (recommended)
helm repo add kedacore https://kedacore.github.io/keda-helm-charts
helm install keda kedacore/keda --namespace keda --create-namespace

# Or using kubectl
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.12.0/keda-2.12.0.yaml
```

Verify:

```bash
kubectl get pods -n keda
kubectl get crd | grep keda
```
