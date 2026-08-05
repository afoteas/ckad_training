# Tags

[Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#types-of-probe) [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes)

# Question

Solve this question on instance: `ssh ckad5601`


*Deployment* `slow-starter` in *Namespace* `ceres` has a container that needs about `10` seconds to start. Add a probe to the *Deployment* that:

1. Checks the container is reachable via HTTP GET on `/` port `80`
2. Waits 10 seconds before the first check is run
3. Only runs during the start of the container, not continuously

# Answer

*livenessProbe*: Runs continuously, restarts the container if it fails

*readinessProbe*: Runs continuously, marks the *Pod* not Ready while it fails

*startupProbe*: Runs only at container startup, restarts the container if it fails, blocks the other probes until it succeeds

 

###### **Investigate**



```bash
➜ ssh ckad5601


➜ candidate@ckad5601:~$ k -n ceres get deploy,pod
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/slow-starter   1/1     1            1           65s


NAME                                READY   STATUS    RESTARTS   AGE
pod/slow-starter-675479bf9c-w464v   1/1     Running   0          65s
```

We are working here with a simple Nginx *Deployment* which simulates that it takes some time until it's ready. It does this by sneaking a `sleep 10` before starting the `nginx` process.



```bash
➜ candidate@ckad5601:~$ k -n ceres get deploy slow-starter -oyaml


# kubectl -n ceres get deploy slow-starter -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-starter
  namespace: ceres
...
spec:
...
  template:
...
    spec:
      containers:
      - args:
        - sleep 10 && exec nginx -g 'daemon off;'    # nginx starts after 10 seconds
        command:
        - /bin/sh
        - -c
        image: nginx:1-alpine
...
```

No probes are defined yet.

 

###### **Add the startupProbe**

We need to add a startupProbe here because it only runs during the start of the container. The livenessProbe and readinessProbe run continuously for as long as the *Pod* is running.



```bash
➜ candidate@ckad5601:~$ k -n ceres edit deploy slow-starter


# kubectl -n ceres edit deploy slow-starter
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slow-starter
  namespace: ceres
...
spec:
...
  template:
...
    spec:
      containers:
      - args:
        - sleep 10 && exec nginx -g 'daemon off;'
        command:
        - /bin/sh
        - -c
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
        startupProbe:                # ADD
          httpGet:                   # ADD
            path: /                  # ADD
            port: 80                 # ADD
          initialDelaySeconds: 10    # ADD
...
```

We use the `httpGet` and `initialDelaySeconds: 10` as required in the question text.

 

###### **See startupProbe in action**

Adding the startupProbe causes a new rollout, we can see a new *Pod* being created while the old one is still running:



```bash
➜ candidate@ckad5601:~$ k -n ceres get deploy,pod
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/slow-starter   1/1     1            1           10m


NAME                                READY   STATUS    RESTARTS   AGE
pod/slow-starter-588f587f47-fp592   1/1     Running   0          10m
pod/slow-starter-d48cf67cf-57xkk    0/1     Running   0          5s
```

The *Pod* stays `0/1` until the startup probe succeeds. If we describe the new *Pod* we can also see information about the probing:



```bash
➜ candidate@ckad5601:~$ k -n ceres describe pod slow-starter-d48cf67cf-57xkk
Name:             slow-starter-d48cf67cf-57xkk
Namespace:        ceres
...
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
```

Once the probe succeeds it should look like this:



```bash
➜ candidate@ckad5601:~$ k -n ceres describe pod slow-starter-d48cf67cf-57xkk
Name:             slow-starter-d48cf67cf-57xkk
Namespace:        ceres
...
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...


➜ candidate@ckad5601:~$ k -n ceres get deploy,pod
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/slow-starter   1/1     1            1           13m


NAME                               READY   STATUS    RESTARTS   AGE
pod/slow-starter-d48cf67cf-57xkk   1/1     Running   0          2m52s
```

Probes are powerful for application health during container startup or throughout their lifetime.

# Checks

- Container has correct startupProbe with HTTP call
- startupProbe initialDelaySeconds is 10
- Deployment slow-starter has 1 ready Pod

