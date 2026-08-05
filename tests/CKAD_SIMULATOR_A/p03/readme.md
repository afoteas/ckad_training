# Tags

[Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service) [Service](https://kubernetes.io/docs/concepts/services-networking/service)

# Question

Solve this question on instance: `ssh ckad5601`

 

One of EarthAG's *Services* stopped working after the latest rollout. It is in *Namespace* `earth` and should be reachable from inside the cluster.

Find the *Service*, fix any issues and confirm it's working again.

# Answer

First we get an overview of the resources in *Namespace* `earth`:


```bash
➜ ssh ckad5601


➜ candidate@ckad5601:~$ k -n earth get all
NAME                                          READY   STATUS    RESTARTS   AGE
pod/earth-2x3-api-5656d7dcd5-26pp6            1/1     Running   0          163m
pod/earth-2x3-api-5656d7dcd5-bctn5            1/1     Running   0          163m
pod/earth-2x3-api-5656d7dcd5-qb2dq            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-98ckd            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-9mnsf            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-b7w2l            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-pp4mn            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-pp7zj            1/1     Running   0          163m
pod/earth-2x3-web-777fb6947f-tdk9d            1/1     Running   0          163m
pod/earth-3cc-runner-7bc66f5f7c-5vqnk         1/1     Running   0          163m
pod/earth-3cc-runner-7bc66f5f7c-k9nxh         1/1     Running   0          163m
pod/earth-3cc-runner-7bc66f5f7c-zmqkm         1/1     Running   0          163m
pod/earth-3cc-runner-heavy-7849b8d4b7-k6ptk   1/1     Running   0          163m
pod/earth-3cc-runner-heavy-7849b8d4b7-khkrm   1/1     Running   0          163m
pod/earth-3cc-runner-heavy-7849b8d4b7-nwxhd   1/1     Running   0          163m
pod/earth-3cc-web-5cbdcd777b-hw89p            0/1     Running   0          162m
pod/earth-3cc-web-5cbdcd777b-jskfr            0/1     Running   0          162m
pod/earth-3cc-web-5cbdcd777b-p7m25            0/1     Running   0          162m
pod/earth-3cc-web-5cbdcd777b-rpd2d            0/1     Running   0          162m


NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/earth-2x3-api-svc   ClusterIP   10.101.30.167   <none>        4546/TCP   163m
service/earth-2x3-web-svc   ClusterIP   10.111.210.80   <none>        4545/TCP   163m
service/earth-3cc-web       ClusterIP   10.100.47.137   <none>        6363/TCP   163m


NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/earth-2x3-api            3/3     3            3           163m
deployment.apps/earth-2x3-web            6/6     6            6           163m
deployment.apps/earth-3cc-runner         3/3     3            3           163m
deployment.apps/earth-3cc-runner-heavy   3/3     3            3           163m
deployment.apps/earth-3cc-web            0/4     4            0           163m


NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/earth-2x3-api-5656d7dcd5            3         3         3       163m
replicaset.apps/earth-2x3-web-777fb6947f            6         6         6       163m
replicaset.apps/earth-3cc-runner-7bc66f5f7c         3         3         3       163m
replicaset.apps/earth-3cc-runner-heavy-7849b8d4b7   3         3         3       163m
replicaset.apps/earth-3cc-web-5cbdcd777b            4         4         0       162m
replicaset.apps/earth-3cc-web-d6d9d5c7d             0         0         0       163m
```

First impression could be that all *Pods* are in status RUNNING. But looking closely we see that some of the *Pods* are not ready, which also confirms what we see about one *Deployment* and one *ReplicaSet*. This could be our error to further investigate.

Another approach could be to check the *Services* for missing endpoints, which could be a selector/label misconfiguration or the endpoints are actually not available/ready.



```bash
➜ candidate@ckad5601:~$ k -n earth get endpointslice
NAME                      ...  ENDPOINTS                                      ...
earth-2x3-api-svc-jj8v5   ...  10.32.0.19,10.32.0.20,10.32.0.21               ...
earth-2x3-web-svc-tn55s   ...  10.32.0.14,10.32.0.15,10.32.0.16 + 3 more...   ...
earth-3cc-web-gsvbx       ...  10.32.0.28,10.32.0.30,10.32.0.31 + 1 more...   ...


➜ candidate@ckad5601:~$ k -n earth describe endpointslice earth-3cc-web-gsvbx
```
```yaml
# kubectl -n earth describe endpointslice earth-3cc-web-gsvbx
Name:         earth-3cc-web-gsvbx
Namespace:    earth
Labels:       endpointslice.kubernetes.io/managed-by=endpointslice-controller.k8s.io
              id=earth-3cc-web
              kubernetes.io/service-name=earth-3cc-web
Annotations:  <none>
AddressType:  IPv4
Ports:
  Name     Port  Protocol
  ----     ----  --------
  6363-80  80    TCP
Endpoints:
  - Addresses:  10.32.0.28
    Conditions:
      Ready:    false                 # NOT READY
    Hostname:   <unset>
    TargetRef:  Pod/earth-3cc-web-5cbdcd777b-jskfr
    NodeName:   ckad5601
    Zone:       <unset>
  - Addresses:  10.32.0.30
    Conditions:
      Ready:    false                 # NOT READY
    Hostname:   <unset>
    TargetRef:  Pod/earth-3cc-web-5cbdcd777b-hw89p
    NodeName:   ckad5601
    Zone:       <unset>
...
```

*Service* `earth-3cc-web` doesn't have ready endpoints.

Checking all *Services* for connectivity should show the same (this step is optional and just for demonstration). ClusterIPs are routable from the controlplane, so we can curl them directly:



```bash
➜ candidate@ckad5601:~$ curl -m 5 10.101.30.167:4546
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>


➜ candidate@ckad5601:~$ curl -m 5 10.111.210.80:4545
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>


➜ candidate@ckad5601:~$ curl -m 5 10.100.47.137:6363
curl: (7) Failed to connect to 10.100.47.137 port 6363 after 0 ms: Couldn't connect to server
```

We get no connection to `earth-3cc-web` on `10.100.47.137:6363`. Let's look at the *Deployment* `earth-3cc-web`. Here we see that the requested amount of replicas is not available/ready:



```bash
➜ candidate@ckad5601:~$ k -n earth get deploy earth-3cc-web
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
earth-3cc-web   0/4     4            0           167m
```

To continue we check the *Deployment* YAML for some misconfiguration:



```bash
➜ candidate@ckad5601:~$ k -n earth edit deploy earth-3cc-web
```
```yaml
# kubectl -n earth edit deploy earth-3cc-web
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "3"   # there have been rollouts
    ...
  generation: 3                              # there have been rollouts
  name: earth-3cc-web
  namespace: earth
...
spec:
...
  template:
    metadata:
      creationTimestamp: null
      labels:
        id: earth-3cc-web
        version: v2
    spec:
      containers:
      - image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
        readinessProbe:
          failureThreshold: 3
          initialDelaySeconds: 10
          periodSeconds: 20
          successThreshold: 1
          tcpSocket:
            port: 82                # this port doesn't seem to be right, should be 80
          timeoutSeconds: 1
...
```

We change the readiness-probe port, save and check the *Pods* after waiting a bit:



```bash
➜ candidate@ckad5601:~$ k -n earth get pod -l id=earth-3cc-web
NAME                             READY   STATUS    RESTARTS   AGE
earth-3cc-web-5866f6d578-2ltsg   1/1     Running   0          31s
earth-3cc-web-5866f6d578-5cjxc   1/1     Running   0          31s
earth-3cc-web-5866f6d578-bp7p2   1/1     Running   0          31s
earth-3cc-web-5866f6d578-zk2h7   1/1     Running   0          31s
```

Let's check the service again:



```bash
➜ candidate@ckad5601:~$ curl -m 5 10.100.47.137:6363
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
...
```

We did it!