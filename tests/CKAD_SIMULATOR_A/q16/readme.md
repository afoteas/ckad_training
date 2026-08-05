# Tags

[Image Pull Policy](https://kubernetes.io/docs/concepts/containers/images#image-pull-policy) [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers) [Pod Termination](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)

# Question

Solve this question on instance: `ssh ckad7326`

 

*Deployment* `harvester` in *Namespace* `titan` runs an app container with a sidecar. Configure:

1. The application container should only pull the image if it's not available already on the node
2. The sidecar container should never pull the image
3. *Pods* should be given up to 60 seconds to shut down gracefully on termination 

# Answer

Kubernetes will download container images automatically, but the behaviour can also be configured by setting the `imagePullPolicy` to either:

- *Always*: Pull on every *Pod* start
- *IfNotPresent*: Pull only if the image is missing from the node
- *Never*: Don't pull, fail if the image isn't already on the node

If unset, `imagePullPolicy` defaults to `Always` when the image tag is `:latest` or omitted, and to `IfNotPresent` for any other (pinned) tag. It makes sense because a `:latest` tag is expected to change quite often.

 

###### **About Pod termination**

Ever wonder why a *Pod* stays longer in the terminating state after deletion? It's intended and gives applications time to end whatever they're still doing in a clean way.

On a *Pod* delete (rollout, scale-down, eviction) a *Pod* is put into the terminating state for up to `spec.terminationGracePeriodSeconds` (default `30`). But a *Pod* can also be removed earlier if the container processes listen to `SIGTERM` and exit gracefully themselves.

 
###### **Investigate**

We look at the current state of the *Deployment*:

```bash
➜ ssh ckad7326

➜ candidate@ckad7326:~$ k -n titan get deploy,pod
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/harvester   1/1     1            1           7m

NAME                             READY   STATUS    RESTARTS   AGE
pod/harvester-6985c68cff-sf7j7   2/2     Running   0          7m
```

The *Pod* is running. Now we check the current pull policies on both containers:


```bash
➜ candidate@ckad7326:~$ k -n titan get deploy harvester -oyaml
```
```yaml
# kubectl -n titan get deploy harvester -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: harvester
  namespace: titan
...
spec:
...
  template:
...
    spec:
      containers:
      - image: nginx:1-alpine
        imagePullPolicy: Always # interesting
        name: nginx
...
      initContainers:
      - command:
        - bash
        - -c
        - sleep infinity
        image: bash:5
        imagePullPolicy: Always # interesting
        name: harvester-side
        resources:
          requests:
            cpu: 10m
            memory: 20Mi
        restartPolicy: Always
        terminationMessagePath: /dev/termination-log
...
      terminationGracePeriodSeconds: 30  # interesting
...
```

Both containers use `imagePullPolicy: Always`, so the kubelet contacts a registry on every restart. That's wasteful for the app and forbidden for the sidecar. The *Pod* also keeps the default `terminationGracePeriodSeconds: 30`, half a minute is too short for graceful shutdown.

 ###### **Adjust the configuration**

```bash
➜ candidate@ckad7326:~$ k -n titan edit deploy harvester
```

```yaml
# kubectl -n titan edit deploy harvester
apiVersion: apps/v1
kind: Deployment
metadata:
  name: harvester
  namespace: titan
...
spec:
...
  template:
    metadata:
      labels:
        app: harvester
    spec:
      containers:
      - image: nginx:1-alpine
        imagePullPolicy: IfNotPresent    # UPDATE
...
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - bash
        - -c
        - sleep infinity
        image: bash:5
        imagePullPolicy: Never           # UPDATE
...
      terminationGracePeriodSeconds: 60  # UPDATE
...
```

Save and exit. The *Deployment* rolls out a new *Pod*:

```bash
➜ candidate@ckad7326:~$ k -n titan get pod
NAME                         READY   STATUS    RESTARTS   AGE
harvester-5886f8b4d6-q8wr4   2/2     Running   0          9m
```

The `2/2` ready confirms both the sidecar and the app container are up and running with the new policies.

# Checks

- App container nginx has imagePullPolicy IfNotPresent
- Sidecar harvester-side has imagePullPolicy Never
- Pod has terminationGracePeriodSeconds 60
- Deployment harvester has 1 ready Pod

