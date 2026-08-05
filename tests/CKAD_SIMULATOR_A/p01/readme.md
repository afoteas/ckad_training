# Tags

[Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes)

# Question

Solve this question on instance: `ssh ckad9043`

 

In *Namespace* `pluto` there is a *Deployment* named `project-23-api`. Implement a liveness-probe which checks the container to be reachable on port `80`.

Initially the probe should wait `10`, periodically `15` seconds.

The original *Deployment* YAML is available at `/course/p1/project-23-api.yaml`.

Save your changes at `/course/p1/project-23-api-new.yaml` and apply the changes.

 

# Answer

First we get an overview:


```bash
➜ ssh ckad9043


➜ candidate@ckad9043:~$ k -n pluto get all -o wide
NAME                                  READY   STATUS    ... IP           ...
pod/holy-api                          1/1     Running   ... 10.12.0.26   ...
pod/project-23-api-784857f54c-dx6h6   1/1     Running   ... 10.12.2.15   ...
pod/project-23-api-784857f54c-sj8df   1/1     Running   ... 10.12.1.18   ...
pod/project-23-api-784857f54c-t4xmh   1/1     Running   ... 10.12.0.23   ...


NAME                             READY   UP-TO-DATE   AVAILABLE   ...
deployment.apps/project-23-api   3/3     3            3           ...
```

To note: we see another *Pod* here called `holy-api` which is part of another section. This is often the case in the provided scenarios, so be careful to only manipulate the resources you need to. Just like in the real world and in the exam.

Next we use `nginx:1-alpine` and `curl` to check if one *Pod* is accessible on port 80:



```bash
➜ candidate@ckad9043:~$ k run tmp --restart=Never --rm -i --image=nginx:1-alpine -- curl -m 5 10.12.2.15
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

We could also use `busybox:1` and `wget` for this:

``` bash
➜ candidate@ckad9043:~$ k run tmp --restart=Never --rm --image=busybox:1 -i -- wget -O- 10.12.2.15
Connecting to 10.12.2.15 (10.12.2.15:80)
writing to stdout
-                    100% |********************************|   612  0:00:00 ETA
written to stdout
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Now that we're sure the *Deployment* works we can continue with altering the provided YAML:



```bash
➜ candidate@ckad9043:~$ cp /course/p1/project-23-api.yaml /course/p1/project-23-api-new.yaml


➜ candidate@ckad9043:~$ vim /course/p1/project-23-api-new.yaml
```

Add the liveness-probe to the YAML:

``` yaml
# ckad9043:/course/p1/project-23-api-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-23-api
  namespace: pluto
spec:
  replicas: 3
  selector:
    matchLabels:
      app: project-23-api
  template:
    metadata:
      labels:
        app: project-23-api
    spec:
      volumes:
      - name: cache-volume1
        emptyDir: {}
      - name: cache-volume2
        emptyDir: {}
      - name: cache-volume3
        emptyDir: {}
      containers:
      - image: httpd:2-alpine
        name: httpd
        volumeMounts:
        - mountPath: /cache1
          name: cache-volume1
        - mountPath: /cache2
          name: cache-volume2
        - mountPath: /cache3
          name: cache-volume3
        env:
        - name: APP_ENV
          value: "prod"
        - name: APP_SECRET_N1
          value: "IO=a4L/XkRdvN8jM=Y+"
        - name: APP_SECRET_P1
          value: "-7PA0_Z]>{pwa43r)__"
        livenessProbe:                  # add
          tcpSocket:                    # add
            port: 80                    # add
          initialDelaySeconds: 10       # add
          periodSeconds: 15             # add
```

Then let's apply the changes:



```bash
➜ candidate@ckad9043:~$ k -f /course/p1/project-23-api-new.yaml apply
```

Next we wait 10 seconds and confirm the *Pods* are still running:


```bash
➜ candidate@ckad9043:~$ k -n pluto get pod
NAME                              READY   STATUS    RESTARTS   AGE
holy-api                          1/1     Running   0          144m
project-23-api-5b4579fd49-8knh8   1/1     Running   0          90s
project-23-api-5b4579fd49-cbgph   1/1     Running   0          88s
project-23-api-5b4579fd49-tcfq5   1/1     Running   0          86s
```

We can also check the configured liveness-probe settings on a *Pod* or the *Deployment*:


```bash
➜ candidate@ckad9043:~$ k -n pluto describe pod project-23-api-5b4579fd49-8knh8 | grep Liveness
    Liveness:   tcp-socket :80 delay=10s timeout=1s period=15s #success=1 #failure=3


➜ candidate@ckad9043:~$ k -n pluto describe deploy project-23-api | grep Liveness
    Liveness:   tcp-socket :80 delay=10s timeout=1s period=15s #success=1 #failure=3
```


