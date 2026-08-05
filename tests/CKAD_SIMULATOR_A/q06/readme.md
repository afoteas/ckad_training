# Tags

[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment) [Rolling Update Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment#rolling-update-deployment)

 

# Question

Solve this question on instance: `ssh ckad5601`

In *Namespace* `mercury` the team runs *Deployment* `cassini` with 4 replicas. They want zero-downtime rollouts and a faster cutover. Configure the *Deployment*'s rolling update strategy:

1. During a rollout up to `2` additional *Pods* may be created above the desired replica count
2. No *Pod* may be unavailable at any time

Afterwards trigger a new rollout by setting the container environment variable `APP_VERSION` to `"2"`.

# Answer

*maxSurge*: How many *Pods* may exist above the desired count during a rollout

*maxUnavailable*: How many may be missing during a rollout

 

###### **Investigate**

```bash
➜ ssh ckad5601

➜ candidate@ckad5601:~$ k -n mercury get deploy cassini

NAME      READY   UP-TO-DATE   AVAILABLE   AGE

cassini   4/4     4            4           2m51s
```



```bash
➜ candidate@ckad5601:~$ k -n mercury get deploy cassini -oyaml
yaml
# kubectl -n mercury get deploy cassini -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cassini
  namespace: mercury
...
spec:
...
  strategy:
    rollingUpdate:
      maxSurge: 25%         # default value
      maxUnavailable: 25%   # default value
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: cassini
    spec:
      containers:
      - env:
        - name: APP_VERSION
          value: "1"
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
...
```

No `strategy` was set in the manifest, so the defaults `25%` / `25%` are used. For 4 replicas that means at most 1 surge and 1 unavailable.

 

###### **Set the rolling update strategy**

We need 2 surge and 0 unavailable. Both integers and percentages are allowed; here we use integers.

```bash

➜ candidate@ckad5601:~$ k -n mercury edit deploy cassini
```


```yaml
# kubectl -n mercury edit deploy cassini

apiVersion: apps/v1
kind: Deployment
metadata:
  name: cassini
  namespace: mercury
...
spec:
...
  strategy:
    rollingUpdate:
      maxSurge: 2         # UPDATE
      maxUnavailable: 0   # UPDATE
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: cassini
    spec:
      containers:
      - env:
        - name: APP_VERSION
          value: "1"
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
...
```

Save and exit. Were *Pods* restarted?


```bash
➜ candidate@ckad5601:~$ k -n mercury get pod
NAME                       READY   STATUS    RESTARTS   AGE
cassini-8494bc9d97-5z866   1/1     Running   0          7m13s
cassini-8494bc9d97-g7gsq   1/1     Running   0          7m13s
cassini-8494bc9d97-mmzdj   1/1     Running   0          7m13s
cassini-8494bc9d97-x4qgh   1/1     Running   0          7m13s
```

No, this change alone does not trigger a rollout because the *Pod* template hasn't changed yet.

 

###### **Trigger the rollout**

We bump the env variable as required:


``` bash
➜ candidate@ckad5601:~$ k -n mercury edit deploy cassini
```


``` yaml
# kubectl -n mercury edit deploy cassini
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cassini
  namespace: mercury
...
spec:
...
  strategy:
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0
    type: RollingUpdate
  template:
...
    spec:
      containers:
      - env:
        - name: APP_VERSION
          value: "2"             # UPDATE
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
...
```

Saving causes a new *ReplicaSet* to be created and the rollout to start. We can watch it:


``` bash
➜ candidate@ckad5601:~$ k -n mercury rollout status deploy cassini
Waiting for deployment "cassini" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "cassini" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "cassini" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "cassini" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "cassini" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cassini" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cassini" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cassini" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "cassini" rollout to finish: 1 old replicas are pending termination...
deployment "cassini" successfully rolled out


➜ candidate@ckad5601:~$ k -n mercury get pod
NAME                       READY   STATUS    RESTARTS   AGE
cassini-6c5f4bc8cb-2fbzz   1/1     Running   0          17s
cassini-6c5f4bc8cb-cq5hd   1/1     Running   0          17s
cassini-6c5f4bc8cb-kxh4l   1/1     Running   0          12s
cassini-6c5f4bc8cb-vfgcz   1/1     Running   0          14s
```

All 4 *Pods* are on the new *ReplicaSet* and serve `APP_VERSION=2`.

# Checks

- Deployment cassini RollingUpdate maxSurge updated
- Deployment cassini RollingUpdate maxUnavailable updated
- Deployment cassini container env APP_VERSION updated

