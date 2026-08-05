# Tags

[Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces)

# Question

Solve this question on instance: `ssh ckad7326`

 

A *Pod* in *Namespace* `saturn` belongs to the e-commerce system `my-happy-shop` of Team Neptune.

The *Pod* name is unknown.

Find it and move it to *Namespace* `neptune`. Recreating is fine.

# Answer

Let's see all those *Pods*:


```bash
➜ ssh ckad7326


➜ candidate@ckad7326:~$ k -n saturn get pod
NAME                READY   STATUS    RESTARTS   AGE
webserver-sat-001   1/1     Running   0          111m
webserver-sat-002   1/1     Running   0          111m
webserver-sat-003   1/1     Running   0          111m
webserver-sat-004   1/1     Running   0          111m
webserver-sat-005   1/1     Running   0          111m
webserver-sat-006   1/1     Running   0          111m
```

The *Pod* names don't reveal any information. We assume the *Pod* we are searching has a *label* or *annotation* with the name `my-happy-shop`, so we search for it:


``` bash
➜ candidate@ckad7326:~$ k -n saturn get pod -o yaml | grep my-happy-shop -A10
      description: this is the server for the E-Commerce System my-happy-shop
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{"description":"this is the server for the E-Commerce System my-happy-shop"},"labels":{"id":"webserver-sat-003"},"name":"webserver-sat-003","namespace":"saturn"},"spec":{"containers":[{"image":"nginx:1-alpine","name":"webserver-sat","resources":{}}],"restartPolicy":"Always"}}
    creationTimestamp: "2026-05-24T11:34:29Z"
    generation: 1
    labels:
      id: webserver-sat-003
    name: webserver-sat-003
    namespace: saturn
    resourceVersion: "3837"
    uid: 62c7e621-0767-43e1-8ee4-0789e6063772
  spec:
    containers:
```

We see the webserver we're looking for is `webserver-sat-003`. Export it to a file and edit:


``` bash
➜ candidate@ckad7326:~$ k -n saturn get pod webserver-sat-003 -o yaml > 7.yaml


➜ candidate@ckad7326:~$ vim 7.yaml
```

Change the *Namespace* to `neptune`, also remove the `status:` section, the token `volume`, the token `volumeMount` and the `nodeName`, else the new *Pod* won't start. The final file could look as clean as this:


```yaml
# ckad7326:/home/candidate/7.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    description: this is the server for the E-Commerce System my-happy-shop
  labels:
    id: webserver-sat-003
  name: webserver-sat-003
  namespace: neptune                   # new namespace here
spec:
  containers:
  - image: nginx:1-alpine
    imagePullPolicy: IfNotPresent
    name: webserver-sat
  restartPolicy: Always
```

Then we execute:


```bash
➜ candidate@ckad7326:~$ k -n neptune create -f 7.yaml
pod/webserver-sat-003 created


➜ candidate@ckad7326:~$ k -n neptune get pod | grep webserver
webserver-sat-003               1/1     Running   0          22s
```

It seems the server is running in *Namespace* `neptune`, so we can delete the original:


```bash
➜ candidate@ckad7326:~$ k -n saturn delete pod webserver-sat-003 --force --grace-period=0
pod "webserver-sat-003" force deleted
```

Let's confirm only one is running:


``` bash
➜ candidate@ckad7326:~$ k get pod -A | grep webserver-sat-003
neptune        webserver-sat-003   1/1     Running   0          6s
```

This should list only one pod called `webserver-sat-003` in *Namespace* `neptune`, status running.

# Checks

- Pod webserver-sat-003 is running in namespace neptune
- Pod has label id=webserver-sat-003
- Pod has exactly 1 container
- Container is named webserver-sat
- Container uses image nginx:1-alpine
- Old pod webserver-sat-003 in namespace saturn has been removed

