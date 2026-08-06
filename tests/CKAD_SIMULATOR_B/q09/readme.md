# Tags

[Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service) [Service](https://kubernetes.io/docs/concepts/services-networking/service)

# Question

Solve this question on instance: `ssh ckad3250`

 

In *Namespace* `pine` the ClusterIP *Service* `manager-api-svc` should expose the *Pods* of *Deployment* `manager-api-deployment`, but isn't reachable. Find and fix the misconfiguration.

You can verify with `curl manager-api-svc.pine:4444` or directly against the *Service*'s ClusterIP.

# Answer

First let's get an overview:

```sh
➜ ssh ckad3250

➜ candidate@ckad3250:~$ k -n pine get all
NAME                                         READY   STATUS    RESTARTS   AGE
pod/manager-api-deployment-dbcc6657d-bg2hh   1/1     Running   0          98m
pod/manager-api-deployment-dbcc6657d-f5fv4   1/1     Running   0          98m
pod/manager-api-deployment-dbcc6657d-httjv   1/1     Running   0          98m
pod/manager-api-deployment-dbcc6657d-k98xn   1/1     Running   0          98m
pod/test-init-container-5db7c99857-htx6b     1/1     Running   0          2m19s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/manager-api-svc   ClusterIP   10.15.241.159   <none>        4444/TCP   99m

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/manager-api-deployment   4/4     4            4           98m
deployment.apps/test-init-container      1/1     1            1           2m19s
...
```

Everything seems to be running, but we can't seem to get a connection:

```sh
➜ candidate@ckad3250:~$ curl -m 5 10.15.241.159:4444
curl: (28) Connection timed out after 5000 milliseconds
```

Ok, let's try to connect to one pod directly:

```sh
➜ candidate@ckad3250:~$ k -n pine get pod -o wide
NAME                                       READY   STATUS    ...   IP          NODE
manager-api-deployment-dbcc6657d-bg2hh     1/1     Running   ...   10.0.1.14   ...
...


➜ candidate@ckad3250:~$ curl -m 5 10.0.1.14
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

The *Pods* itself seem to work. Let's investigate the *Service* a bit:

```sh
➜ candidate@ckad3250:~$ k -n pine describe service manager-api-svc
Name:              manager-api-svc
Namespace:         pine
Labels:            app=manager-api-svc
...
Endpoints:         <none>
...
```

Endpoint inspection is also possible using:

```sh
➜ candidate@ckad3250:~$ k -n pine get endpointslice
NAME                   ADDRESSTYPE   PORTS     ENDPOINTS                              AGE
manager-api-svc-x7p2k  IPv4          <unset>   <unset>                                100m
```

No endpoints - No good. We check the *Service* YAML:

```sh
➜ candidate@ckad3250:~$ k -n pine edit service manager-api-svc
```
```yaml
# kubectl -n pine edit service manager-api-svc
apiVersion: v1
kind: Service
metadata:
...
  labels:
    app: manager-api-svc
  name: manager-api-svc
  namespace: pine
...
spec:
  clusterIP: 10.15.241.159
  ports:
  - name: 4444-80
    port: 4444
    protocol: TCP
    targetPort: 80
  selector:
    #id: manager-api-deployment # wrong selector, needs to point to pod!
    id: manager-api-pod
  sessionAffinity: None
  type: ClusterIP
```

Though *Pods* are usually never created without a *Deployment* or *ReplicaSet*, *Services* always select for *Pods* directly. This gives great flexibility because *Pods* could be created through various customized ways. After saving the new selector we check the *Service* again for endpoints:

```sh
➜ candidate@ckad3250:~$ k -n pine get endpointslice
NAME                   ...  PORTS  ENDPOINTS
manager-api-svc-2nlz2  ...  80     10.0.0.30:80,10.0.1.30:80,10.0.1.31:80 + 1 more...
```

Endpoints - Good! Now we try connecting again:

```sh
➜ candidate@ckad3250:~$ curl -m 5 10.15.241.159:4444
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

And we fixed it. Good to know is how to be able to use Kubernetes DNS resolution from a different *Namespace*. Not necessary, but we could spin up the temporary *Pod* in default *Namespace*:

```sh
➜ candidate@ckad3250:~$ k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 manager-api-svc:4444
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (6) Could not resolve host: manager-api-svc
pod "tmp" deleted
pod default/tmp terminated (Error)


➜ candidate@ckad3250:~$ k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 manager-api-svc.pine:4444
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0  68000      0 --:--:-- --:--:-- --:--:-- 68000
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

Short `manager-api-svc.pine` or long `manager-api-svc.pine.svc.cluster.local` work.

# Checks

- Service has correct selector
- Service has Pods as Endpoints

