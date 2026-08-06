# Tags

[ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas) [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range)

# Question

Solve this question on instance: `ssh ckad3250`

*Deployment* `reporter` runs in *Namespace* `cedar-limited`, a tightly-constrained *Namespace*.

1. Scale the *Deployment* to `4` replicas
2. Double the container `cpu` and `memory` requests and limits
3. Adjust any container level resource limitations to the exact amount these *Pods* can request
4. Adjust the max *Namespace* resource limitations so that exactly `5` *Pods* could run

# Answer

*LimitRange* applies per-*Container* constraints (`max`, `min`, `default`, `defaultRequest`). It says "no individual *Container* may exceed this".

*ResourceQuota* applies *Namespace*-wide limit: the sum of resource requests across all *Pods*, or object count like "total number of pods".

###### **Scale up to 4 replicas and see limit in action**

We can see the *Deployment* has two *Pods*:

```sh
➜ ssh ckad3250

➜ candidate@ckad3250:~$ k -n cedar-limited get pod
NAME                       READY   STATUS    RESTARTS   AGE
reporter-9d5ccd686-glpcg   1/1     Running   0          37s
reporter-9d5ccd686-p8db6   1/1     Running   0          37s
```

Let's try to scale it up to 4 replicas:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited scale deploy reporter --replicas 4
deployment.apps/reporter scaled

➜ candidate@ckad3250:~$ k -n cedar-limited get pod
NAME                       READY   STATUS    RESTARTS   AGE
reporter-9d5ccd686-glpcg   1/1     Running   0          3m
reporter-9d5ccd686-p8db6   1/1     Running   0          3m

➜ candidate@ckad3250:~$ k -n cedar-limited get rs
NAME                 DESIRED   CURRENT   READY   AGE
reporter-9d5ccd686   4         2         2       3m2s
```

After scaling up the *Deployment* we can see that the *ReplicaSet* wants `4` but only has `2` replicas. In cases where a *Deployment* won't create all the *Pods* we should check the *ReplicaSet* for errors:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited describe rs reporter-9d5ccd686
Name:           reporter-9d5ccd686
Namespace:      cedar-limited
...
Events:
  Type     Reason            Age               From                   Message
  ----     ------            ----              ----                   -------
...
  Warning  FailedCreate      89s                replicaset-controller  Error creating: pods "reporter-9d5ccd686-jsjln" is forbidden: exceeded quota: cedar-quota, requested: requests.cpu=20m,requests.memory=20Mi, used: requests.cpu=40m,requests.memory=40Mi, limited: requests.cpu=40m,requests.memory=40Mi
```

In this question we need to know where these *Namespace*-level constraints come from, namely *ResourceQuota* and *LimitRange*.

###### **Raise container requests and limits**

Before we adjust the *LimitRange* and *ResourceQuota* let's first do the required change on the container resources:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited edit deploy reporter
```
```yaml
# kubectl -n cedar-limited edit deploy reporter
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporter
  namespace: cedar-limited
...
spec:
  replicas: 4                   # ensure this is 4
...
  template:
...
    spec:
      containers:
      - image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: reporter
        resources:
          requests:
            cpu: 40m            # UPDATE
            memory: 40Mi        # UPDATE
          limits:
            cpu: 40m            # UPDATE
            memory: 40Mi        # UPDATE
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
...
```

The result is still that not all *Pods* can be scheduled.

###### **Update the *LimitRange* and *ResourceQuota***

> ℹ️ During issues it could be good to scale down the *Deployment* to `0` replica, wait for all *Pods* to be gone, then scale up again

We need to look at *LimitRange* and *ResourceQuota*, let's do *LimitRange* at first:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited edit limitrange cedar-bounds
```
```yaml
# kubectl -n cedar-limited edit limitrange cedar-bounds
apiVersion: v1
kind: LimitRange
metadata:
  name: cedar-bounds
  namespace: cedar-limited
...
spec:
  limits:
  - default:
      cpu: 20m
      memory: 20Mi
    defaultRequest:
      cpu: 20m
      memory: 20Mi
    max:
      cpu: 40m            # UPDATE from 20m
      memory: 40Mi        # UPDATE from 20Mi
    type: Container
```

Now we also update the *ResourceQuota* so the *Namespace* could host `5` *Pods* at the new size. `5 * 40m = 200m` CPU, `5 * 40Mi = 200Mi` memory:



```sh
➜ candidate@ckad3250:~$ k -n cedar-limited edit resourcequota cedar-quota
```
```yaml
# kubectl -n cedar-limited edit resourcequota cedar-quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cedar-quota
  namespace: cedar-limited
...
spec:
  hard:
    requests.cpu: 200m        # UPDATE: 40*5 is 200
    requests.memory: 200Mi    # UPDATE: 40*5 is 200
status:
  hard:
    requests.cpu: 40m
    requests.memory: 40Mi
  used:
    requests.cpu: 40m
    requests.memory: 40Mi
```

The *Deployment* controller retries on its own, but a `rollout restart` speeds this up:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited rollout restart deploy reporter
deployment.apps/reporter restarted

➜ candidate@ckad3250:~$ k -n cedar-limited get pod
NAME                        READY   STATUS    RESTARTS   AGE
reporter-7dbf6765d5-76tgv   1/1     Running   0          24s
reporter-7dbf6765d5-pthl7   1/1     Running   0          61s
reporter-7dbf6765d5-x8nvq   1/1     Running   0          45s
reporter-7dbf6765d5-zcnnn   1/1     Running   0          61s
```

Check the quota usage to confirm sizing:

```sh
➜ candidate@ckad3250:~$ k -n cedar-limited describe resourcequota cedar-quota
Name:            cedar-quota
Namespace:       cedar-limited
Resource         Used   Hard
--------         ----   ----
requests.cpu     160m   200m
requests.memory  160Mi  200Mi
```

There's one slot of headroom, useful during a rolling deployment: a 5th *Pod* at this size would fit, but a 6th would not.

# Checks

- Deployment reporter has 4 replicas
- Container requests and limits are cpu=40m, memory=40Mi
- 4 reporter Pods are Running
- LimitRange Container max is cpu=40m, memory=40Mi
- ResourceQuota requests.cpu=200m, requests.memory=200Mi

