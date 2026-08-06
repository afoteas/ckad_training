# Tags

[Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers) [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging)

# Question

Solve this question on instance: `ssh ckad6422`

 In *Namespace* `fir`, *Deployment* `cleaner` has a container `cleaner-con` writing logs to `cleaner.log` on a shared volume. The YAML is at `/course/16/cleaner.yaml`.

Add a sidecar container `logger-con` (image `busybox:1`) that mounts the same volume and tails `cleaner.log` to stdout so it's visible via `kubectl logs`.

Save your changes under `/course/16/cleaner-new.yaml` on `ckad6422` and make sure the *Deployment* is running.

# Answer

Sidecar containers in K8s are `initContainers` with `restartPolicy: Always`. Search for "Sidecar Containers" in the K8s Docs to familiarise yourself if necessary.


```sh
➜ ssh ckad6422

➜ candidate@ckad6422:~$ cp /course/16/cleaner.yaml /course/16/cleaner-new.yaml

➜ candidate@ckad6422:~$ vim /course/16/cleaner-new.yaml
```

Add a sidecar container which outputs the log file to stdout:

```yaml
# ckad6422:/course/16/cleaner-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: cleaner
  namespace: fir
spec:
  replicas: 2
  selector:
    matchLabels:
      id: cleaner
  template:
    metadata:
      labels:
        id: cleaner
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      initContainers:
      - name: init
        image: bash:5
        command: ['bash', '-c', 'echo init > /var/log/cleaner/cleaner.log']
        volumeMounts:
        - name: logs
          mountPath: /var/log/cleaner
      - name: logger-con                                                # add
        image: busybox:1                                                # add
        restartPolicy: Always                                           # add
        command: ["sh", "-c", "tail -f /var/log/cleaner/cleaner.log"]   # add
        volumeMounts:                                                   # add
        - name: logs                                                    # add
          mountPath: /var/log/cleaner                                   # add
      containers:
      - name: cleaner-con
        image: bash:5
        args: ['bash', '-c', 'while true; do echo `date`: "remove random file" >> /var/log/cleaner/cleaner.log; sleep 1; done']
        volumeMounts:
        - name: logs
          mountPath: /var/log/cleaner
```

In earlier K8s versions it was default to define sidecar containers as additional application containers under `containers:` like this:

```yaml
# LEGACY example of defining sidecar containers in earlier K8s versions
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  name: cleaner
  namespace: fir
spec:
...
  template:
...
    spec:
...
      initContainers:
      - name: init
        image: bash:5
...
      containers:
      - name: cleaner-con
        image: bash:5
...
      - name: logger-con                                           # LEGACY example
        image: busybox:1                                           # LEGACY example
        command: ["sh", "-c", "tail -f /var/log/cleaner/cleaner.log"]   # LEGACY example
        volumeMounts:                                               # LEGACY example
        - name: logs                                                # LEGACY example
          mountPath: /var/log/cleaner                               # LEGACY example
```

Then apply the changes and check the logs of the sidecar:


```sh
➜ candidate@ckad6422:~$ k -f /course/16/cleaner-new.yaml apply
deployment.apps/cleaner configured
```

This will cause a deployment rollout of which we can get more details:

```sh
➜ candidate@ckad6422:~$ k -n fir rollout history deploy cleaner
deployment.apps/cleaner 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>


➜ candidate@ckad6422:~$ k -n fir rollout history deploy cleaner --revision 1
deployment.apps/cleaner with revision #1
Pod Template:
  Labels:       id=cleaner
        pod-template-hash=588d69f7c4
  Init Containers:
   init:
...


➜ candidate@ckad6422:~$ k -n fir rollout history deploy cleaner --revision 2
deployment.apps/cleaner with revision #2
Pod Template:
  Labels:       id=cleaner
        pod-template-hash=65d67c8f86
  Init Containers:
   init:
    Image:      bash:5
...
   logger-con:
    Image:      busybox:1
...
```

Check *Pod* statuses:

```sh
➜ candidate@ckad6422:~$ k -n fir get pod
NAME                       READY   STATUS        RESTARTS   AGE
cleaner-86b7758668-9pw6t   2/2     Running       0          14s
cleaner-86b7758668-qgh4v   2/2     Running       0          9s
```

Finally check the logs of the logging sidecar container:

```sh
➜ candidate@ckad6422:~$ k -n fir logs cleaner-576967576c-cqtgx -c logger-con
init
Sun Jun 21 14:21:30 UTC 2026: remove random file
Sun Jun 21 14:21:31 UTC 2026: remove random file
...
```

Mystery solved, something is removing files at random ;) It's important to understand how containers can communicate with each other using volumes.

# Checks

- Deployment has new logger sidecar container
- Sidecar container is initContainer with RestartPolicy=Always
- Deployment has two ready replicas
- Deployment logger container correct image
- Deployment logger container correct volumeMount
- File /course/16/cleaner-new.yaml exists

