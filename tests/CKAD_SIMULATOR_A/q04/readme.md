# Tags

[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment) [Services](https://kubernetes.io/docs/concepts/services-networking/service) [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels)

# Question

Solve this question on instance: `ssh ckad9043`

In *Namespace* `venus` two versions of a web app run as *Deployments* `web-blue` and `web-green`. *Service* `web-svc` points to both Deployments right now.

1. Update the image of Deployment web-green from `nginx:1.30-alpine` to `nginx:1.31-alpine`.
2. In `blue-green` deployment fashion, update the *Service* to point to the `web-blue` *Deployment* of the web apps



# Answer

*Blue-green deployment* runs two versions side by side (blue and green) and switches all traffic from one to the other at once by repointing the *Service*, which makes releases and rollbacks instant. But because of this it also uses twice the resources while both versions are running.

###### **Investigate**

Let's check the current situation:

```bash
➜ ssh ckad9043

➜ candidate@ckad9043:~$ k -n venus get deploy,svc
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-blue    2/2     2            2           18m
deployment.apps/web-green   2/2     2            2           18m

NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-svc   ClusterIP   10.96.114.162   <none>        80/TCP    18m
```

The *Service* selector is only `app=web`, so it sends traffic to the blue *and* green Pods. We can curl the *Service* IP (might be a different IP address for you):

```bash
➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-green

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-green

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue
```



###### **Update *Deployment* image**

We can `kubectl edit` the *Deployment* or use `kubectl set image`:

```bash
➜ candidate@ckad9043:~$ k -n venus set image deployment web-green nginx=nginx:1.31-alpine
deployment.apps/web-green image updated

➜ candidate@ckad9043:~$ k -n venus get pod
NAME                         READY   STATUS    RESTARTS   AGE
web-blue-5c5d75d7f6-jfwj2    1/1     Running   0          6m39s
web-blue-5c5d75d7f6-vrnlf    1/1     Running   0          6m39s
web-green-759f5b9df7-pkk4q   1/1     Running   0          10s
web-green-759f5b9df7-xpd5q   1/1     Running   0          13s
```

We can see the *Pods* have been recreated because of the image change.

 

###### **Point *Service* to only one *Deployment***

First we need to see the *Pod* labels the *Deployments* use. *Services* always point to *Pods* via labels, not to the *Deployments* directly.

```bash
➜ candidate@ckad9043:~$ k -n venus get deploy web-blue -oyaml
```

```yaml
# kubectl -n venus get deploy web-blue -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-blue
  namespace: venus
...
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: web
      version: blue
...
  template:
    metadata:
      labels:         # we need to work with these Pod labels
        app: web
        version: blue
    spec:
      containers:
...
```

And for `web-green`:

```bash
➜ candidate@ckad9043:~$ k -n venus get deploy web-green -oyaml
```

```yaml
# kubectl -n venus get deploy web-green -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-green
  namespace: venus
...
spec:
  progressDeadlineSeconds: 600
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: web
      version: green
...
  template:
    metadata:
      labels:          # we need to work with these Pod labels
        app: web
        version: green
    spec:
      containers:
...
```

Now we point the *Service* to blue by adding `version: blue` to its selector:

```bash
➜ candidate@ckad9043:~$ k -n venus edit service web-svc
```

```yaml
# kubectl -n venus edit service web-svc
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: venus
...
spec:
...
  ports:
  - name: "80"
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: web
    version: blue     # ADD
  sessionAffinity: None
  type: ClusterIP
...
```

We need to add the selector `version: blue` in addition to the existing `app: web` one, so we ensure requests really only reach web app *Deployments*. Because the selector `version: blue` alone is too broad and could be used for other apps as well.

Now we see request only hitting web-blue:

```bash
➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue

➜ candidate@ckad9043:~$ curl 10.96.114.162
here is web-blue
```

# Checks

- Service web-svc selector also matches version=blue
- Deployment web-green uses image nginx:1.31-alpine

