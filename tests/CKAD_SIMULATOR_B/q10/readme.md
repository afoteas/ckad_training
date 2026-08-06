# Tags

[Service](https://kubernetes.io/docs/concepts/services-networking/service) [Connecting Applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service)

# Question

Solve this question on instance: `ssh ckad1695`

In *Namespace* `elm`:

1. Create a *Pod* `project-plt-6cc-api` of image `nginx:1-alpine` with label `project: plt-6cc-api`
2. Then create a ClusterIP *Service* `project-plt-6cc-svc` exposing it on port `3333` → container port `80`
3. Then `curl` the *Service* and write the response to `/course/10/service_test.html` on `ckad1695`
4. Also write the *Pod*'s logs (showing the request) to `/course/10/service_test.log` on `ckad1695`

# Answer


```sh
➜ ssh ckad1695

➜ candidate@ckad1695:~$ k -n elm run project-plt-6cc-api --image=nginx:1-alpine --labels project=plt-6cc-api
pod/project-plt-6cc-api created
```

This will create the requested *Pod*. In YAML it would look like this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    project: plt-6cc-api
  name: project-plt-6cc-api
spec:
  containers:
  - image: nginx:1-alpine
    name: project-plt-6cc-api
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Next we create the service:

```sh
➜ candidate@ckad1695:~$ k -n elm expose pod -h
...
Examples:
  # Create a service for a replicated nginx, which serves on port 80 and connects to the containers on port 8000
  kubectl expose rc nginx --port=80 --target-port=8000
  
  # Create a service for a replication controller identified by type and name specified in "nginx-controller.yaml",
which serves on port 80 and connects to the containers on port 8000
  kubectl expose -f nginx-controller.yaml --port=80 --target-port=8000
...


➜ candidate@ckad1695:~$ k -n elm expose pod project-plt-6cc-api --name project-plt-6cc-svc --port 3333 --target-port 80
service/project-plt-6cc-svc exposed
```

Expose will create a YAML where everything is already set for our case and no need to change anything:

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    project: plt-6cc-api
  name: project-plt-6cc-svc   # good
  namespace: elm            # great
spec:
  ports:
  - port: 3333                # awesome
    protocol: TCP
    targetPort: 80            # nice
  selector:
    project: plt-6cc-api      # beautiful
status:
  loadBalancer: {}
```

We could also use `create service` but then we would need to change the YAML afterwards:

```sh
➜ candidate@ckad1695:~$ k -n elm create service -h
...
Examples:
  # Create a new ClusterIP service named my-cs
  kubectl create service clusterip my-cs --tcp=5678:8080
  
  # Create a new ClusterIP service named my-cs (in headless mode)
  kubectl create service clusterip my-cs --clusterip="None"
...

➜ candidate@ckad1695:~$ k -n elm create service clusterip project-plt-6cc-svc --tcp 3333:80 --dry-run=client -oyaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: project-plt-6cc-svc
  name: project-plt-6cc-svc
  namespace: elm
spec:
  ports:
  - name: 3333-80
    port: 3333
    protocol: TCP
    targetPort: 80
  selector:
    app: project-plt-6cc-svc
  type: ClusterIP
status:
  loadBalancer: {}
```

Now we would need to set the correct selector labels.

Check the *Service* is running:

```sh
➜ candidate@ckad1695:~$ k -n elm get pod,svc | grep 6cc
pod/project-plt-6cc-api         1/1     Running   0          9m42s

service/project-plt-6cc-svc   ClusterIP   10.31.241.234   <none>        3333/TCP   2m24s
```

Does the *Service* have one *Endpoint*?

```sh
➜ candidate@ckad1695:~$ k -n elm describe svc project-plt-6cc-svc
Name:              project-plt-6cc-svc
Namespace:         elm
Labels:            project=plt-6cc-api
Annotations:       <none>
Selector:          project=plt-6cc-api
Type:              ClusterIP
IP:                10.3.244.240
Port:              <unset>  3333/TCP
TargetPort:        80/TCP
Endpoints:         10.28.2.32:80 
Session Affinity:  None
Events:            <none>
```

Or even shorter:

```sh
➜ candidate@ckad1695:~$ k -n elm get endpointslice
NAME                        ADDRESSTYPE   PORTS   ENDPOINTS    AGE
project-plt-6cc-svc-w58pc   IPv4          80      10.28.2.32   17h
```

Yes, endpoint exists! The *Service*'s ClusterIP is routable from the master, so we can curl it directly:

```sh
➜ candidate@ckad1695:~$ curl -s http://10.31.241.234:3333
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
...
```

Pipe the html content into `/course/10/service_test.html`:


```sh
➜ candidate@ckad1695:~$ curl -s http://10.31.241.234:3333 > /course/10/service_test.html
```
```html
# /course/10/service_test.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
...
```

Also the requested logs:
```bash
➜ candidate@ckad1695:~$ k -n elm logs project-plt-6cc-api > /course/10/service_test.log
```
```log
# /course/10/service_test.log
10.44.0.0 - - [21/Jun/2026:14:21:30 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/8.5.0" "-"
```

# Checks

- Service type ClusterIP exists
- Service has correct selector
- Service has correct port
- Pod exists
- Pod is running
- Pod has correct container image
- Pod has correct label
- File /course/10/service_test.html valid
- File /course/10/service_test.log valid

