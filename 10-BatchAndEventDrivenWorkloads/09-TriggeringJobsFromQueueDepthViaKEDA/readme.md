# Triggering Jobs from Queue Depth via KEDA

This demo shows how to use KEDA's `ScaledJob` resource to automatically create and run Kubernetes Jobs based on message queue depth, without manual intervention.

## Prerequisites

- Kubernetes cluster with KEDA installed
- External event source (Azure Storage Queue, AWS SQS, RabbitMQ, Kafka, etc.)
- Connection credentials for the event source

## Architecture

```
Azure Storage Queue (or similar)
           ↓ (KEDA monitors queue depth)
    KEDA ScaledJob
           ↓
   Creates Kubernetes Job
           ↓
   Pods process messages
           ↓ (Job completes when queue is empty)
   Job deleted / Job succeeds
```

## Setup Steps

### 1. Create a Secret with Connection Credentials

Store connection string as a Kubernetes Secret (base64 encoded):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: azure-queue-auth
type: Opaque
stringData:
  STORAGE_CONNECTIONSTRING: DefaultEndpointsProtocol=https;AccountName=...
```

Deploy:

```bash
kubectl apply -f secret.yaml
```

### 2. Create a TriggerAuthentication

Reference the Secret without exposing it in the ScaledJob:

```yaml
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: azure-queue-auth
spec:
  secretTargetRef:
    - parameter: connection
      name: azure-queue-auth
      key: STORAGE_CONNECTIONSTRING
```

### 3. Create a ScaledJob

Define the Job to create and the trigger metric:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: queue-processor
spec:
  maxReplicaCount: 10              # max concurrent Jobs
  minReplicaCount: 0               # scale to zero when idle
  pollingInterval: 30              # check queue every 30 seconds
  jobTargetRef:
    template:
      spec:
        containers:
          - name: worker
            image: queue-worker:1.0
            env:
              - name: CONNECTION_STRING
                valueFrom:
                  secretKeyRef:
                    name: azure-queue-auth
                    key: STORAGE_CONNECTIONSTRING
            command: ["/bin/sh", "-c"]
            args: ["process-queue.sh"]
        restartPolicy: Never
  triggers:
    - type: azure-queue
      metadata:
        queueName: tasks
        connectionFromEnv: CONNECTION_STRING
```

## Deploy

```bash
kubectl apply -f scaledjob.yaml
```

## Monitor

```bash
# Watch Jobs being created as queue depth increases
kubectl get jobs --watch

# See ScaledJob status
kubectl get scaledjob queue-processor

# View logs from a specific Job
kubectl logs <job-name>
```

## Behavior

- **queue empty**: `maxReplicaCount: 0` → no Jobs running (scale-to-zero)
- **queue depth increases**: KEDA detects messages → creates up to `maxReplicaCount` Jobs
- **polling interval**: every 30 seconds, KEDA checks the queue and adjusts Job count
- **Job success**: when the Job completes, Kubernetes removes it
- **queue empties**: no new Jobs created; existing Jobs complete → eventually reach 0 replicas

## Key Parameters

| Parameter | Purpose |
|---|---|
| `maxReplicaCount` | Maximum number of concurrent Jobs to create |
| `minReplicaCount` | Minimum number (0 enables scale-to-zero) |
| `pollingInterval` | How often (seconds) to check the external metric |
| `queueName` | Name of the queue/topic to monitor |
| `connectionFromEnv` | Inject connection string as env var into Job |

## Cost Benefits

Without KEDA, you would either:

- Keep N worker pods running 24/7 → costs even when idle
- Manually spin up pods when queue fills → slow, error-prone

With KEDA:

- Jobs created only when messages appear
- Scale automatically with queue depth
- Complete and terminate when queue is empty
- **result**: pay only for work done, not idle capacity

## Cleanup

```bash
# Delete the ScaledJob
kubectl delete scaledjob queue-processor

# Delete the Secret and TriggerAuthentication
kubectl delete secret azure-queue-auth
kubectl delete triggerauthentication azure-queue-auth
```

This also deletes any running Jobs created by the ScaledJob.
