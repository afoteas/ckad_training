# Tags

[Service](https://kubernetes.io/docs/concepts/services-networking/service)

# Question

Solve this question on instance: `ssh ckad5601`
 

In *Namespace* `jupiter` you'll find an apache *Deployment* (with one replica) named `jupiter-crew-deploy` and a ClusterIP *Service* called `jupiter-crew-svc` which exposes it. Change this service to a NodePort one to make it available on all nodes on port 30100.

Test this on a node of the cluster: `curl` the node's internal IP on port 30100.

# Answer

First we get an overview:


```bash
➜ ssh ckad5601


➜ candidate@ckad5601:~$ k -n jupiter get all
NAME                                      READY   STATUS    RESTARTS   AGE
pod/jupiter-crew-deploy-8cdf99bc9-klwqt   1/1     Running   0          34m


NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/jupiter-crew-svc   ClusterIP   10.100.254.66   <none>        8080/TCP   34m
...
```

(Optional) Next we check if the ClusterIP *Service* actually works. The ClusterIP is routable from the node, so we can curl it directly:


```bash
➜ candidate@ckad5601:~$ curl 10.100.254.66:8080
<html><body><h1>It works!</h1></body></html>
```

The *Service* is working great. Next we change the *Service* type to NodePort and set the port:



```bash
➜ candidate@ckad5601:~$ k -n jupiter edit service jupiter-crew-svc
```

```yaml
# kubectl -n jupiter edit service jupiter-crew-svc
apiVersion: v1
kind: Service
metadata:
  name: jupiter-crew-svc
  namespace: jupiter
...
spec:
  clusterIP: 10.3.245.70
  ports:
  - name: 8080-80
    port: 8080
    protocol: TCP
    targetPort: 80
    nodePort: 30100             # add the nodePort
  selector:
    id: jupiter-crew
  sessionAffinity: None
  #type: ClusterIP
  type: NodePort                # change type
status:
  loadBalancer: {}
```

We check if the *Service* type was updated:


```bash
➜ candidate@ckad5601:~$ k -n jupiter get svc
NAME               TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
jupiter-crew-svc   NodePort   10.3.245.70   <none>        8080:30100/TCP   3m52s
```

(Optional) And we confirm that the service is still reachable internally:

```bash
➜ candidate@ckad5601:~$ curl 10.3.245.70:8080
<html><body><h1>It works!</h1></body></html>
```

Nice. A NodePort *Service* kind of lies on top of a ClusterIP one, making the ClusterIP *Service* reachable on the Node IPs (internal and external). Next we get the *internal* IPs of all nodes to check the connectivity:



``` bash
➜ candidate@ckad5601:~$ k get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP      ...
ckad5601   Ready    control-plane   18h   v1.35.1   192.168.100.11   ...
```

We can test the connection using the node IP:



```bash
➜ candidate@ckad5601:~$ curl 192.168.100.11:30100
<html><body><h1>It works!</h1></body></html>
```

Here we only have one node in the cluster, but the *Service* would be reachable on all of them. Even if the *Pod* is just running on one specific node, the *Service* makes it available through port 30100 on the internal and external IP addresses of all nodes. This is at least the common/default behaviour but can depend on cluster configuration.


# Checks

- Service is of type NodePort
- Service NodePort has correct port

