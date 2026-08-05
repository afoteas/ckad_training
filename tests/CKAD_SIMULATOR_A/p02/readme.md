# Tags

[Connecting Applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service) [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account)

# Question

Solve this question on instance: `ssh ckad9043`

 

Team Sun needs a new *Deployment* named `sunny` with `4` replicas of image `nginx:1-alpine` in *Namespace* `sun`. The *Deployment* and its *Pods* should use the existing *ServiceAccount* `sa-sun-deploy`.

Expose the *Deployment* internally using a ClusterIP *Service* named `sun-srv` on port `9999`. The nginx containers should run as default on port `80`.

Finally, write a `kubectl` command into file `/course/p2/sunny_status_command.sh` which checks if all *Pods* are running.

 

# Answer


```bash
➜ ssh ckad9043


➜ candidate@ckad9043:~$ k -n sun create deployment -h #help


➜ candidate@ckad9043:~$ k -n sun create deployment sunny --image=nginx:1-alpine --replicas=4 --dry-run=client -oyaml > p2_sunny.yaml


➜ candidate@ckad9043:~$ vim p2_sunny.yaml
```

Then alter its YAML to include the requirements:



```yaml
# ckad9043:/home/candidate/p2_sunny.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: sunny
  name: sunny
  namespace: sun
spec:
  replicas: 4
  selector:
    matchLabels:
      app: sunny
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: sunny
    spec:
      serviceAccountName: sa-sun-deploy     # add
      containers:
      - image: nginx:1-alpine
        name: nginx
        resources: {}
status: {}
```

Now create the YAML and confirm it's running:



```bash
➜ candidate@ckad9043:~$ k create -f p2_sunny.yaml
deployment.apps/sunny created


➜ candidate@ckad9043:~$ k -n sun get pod
NAME                     READY   STATUS        RESTARTS   AGE
0509649a                 1/1     Running       0          149m
0509649b                 1/1     Running       0          149m
1428721e                 1/1     Running       0          149m
...
sunny-64df8dbdbb-9mxbw   1/1     Running       0          10s
sunny-64df8dbdbb-mp5cf   1/1     Running       0          10s
sunny-64df8dbdbb-pggdf   1/1     Running       0          6s
sunny-64df8dbdbb-zvqth   1/1     Running       0          7s
```

Confirmed, the AGE column is always important information about if changes were applied. Next we expose the *Pods* by creating the *Service*:



```bash
➜ candidate@ckad9043:~$ k -n sun expose -h # help


➜ candidate@ckad9043:~$ k -n sun expose deployment sunny --name sun-srv --port 9999 --target-port 80
```

Using expose instead of `kubectl create service clusterip` is faster because it already sets the correct selector-labels. The previous command would produce this YAML:



```yaml
# kubectl -n sun expose deployment sunny --name sun-srv --port 9999 --target-port 80
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: sunny
  name: sun-srv         # required by task
spec:
  ports:
  - port: 9999          # service port
    protocol: TCP
    targetPort: 80      # target port
  selector:
    app: sunny          # selector is important
status:
  loadBalancer: {}
```

Let's test the *Service* using `curl` from a temporary *Pod*:

```bash
➜ candidate@ckad9043:~$ k run tmp --restart=Never --rm -i --image=nginx:1-alpine -- curl -m 5 sun-srv.sun:9999
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Because the *Service* is in a different *Namespace* as our temporary *Pod*, it is reachable using the names `sun-srv.sun` or fully: `sun-srv.sun.svc.cluster.local`.

Finally we need a command which can be executed to check if all *Pods* are running, this can be done with:

```bash
➜ candidate@ckad9043:~$ vim /course/p2/sunny_status_command.sh


# ckad9043:/course/p2/sunny_status_command.sh
kubectl -n sun get deployment sunny
```

To run the command:


```bash
➜ candidate@ckad9043:~$ sh /course/p2/sunny_status_command.sh
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
sunny   4/4     4            4           13m
```

 

 

