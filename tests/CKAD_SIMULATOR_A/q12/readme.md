# Tags

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) [Ingress Path Types](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)

# Question

Solve this question on instance: `ssh ckad5601`

 

In *Namespace* `titan` there are two *Deployments* `app1` and `app2` with *Services*. An *Ingress* controller is installed in the cluster and reachable via `http://titan.galaxy.mine:30080`.

Create an *Ingress* `titan-ing` in *Namespace* `titan`:

- Use and set the existing *IngressClass*
- Use existing *Services* without creating new ones
- Path `/app1` should route to *Pods* of *Deployment* `app1`
- Path `/app2` should route to *Pods* of *Deployment* `app2`

 # Answer

###### **Investigate**

```bash
➜ ssh ckad5601


➜ candidate@ckad5601:~$ k -n titan get deploy,svc
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app1   1/1     1            1           86s
deployment.apps/app2   1/1     1            1           85s


NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/app1   ClusterIP   10.107.202.195   <none>        80/TCP     86s
service/app2   ClusterIP   10.105.12.121    <none>        8080/TCP   85s
```

The Traefik Ingress Controller runs in its own *Namespace* and is already exposed as a NodePort *Service*:

```
➜ candidate@ckad5601:~$ k -n traefik get svc traefik
NAME      TYPE       ...   PORT(S)                      AGE
traefik   NodePort   ...   80:30080/TCP,443:30443/TCP   101s
```

To find the *IngressClass* name we'll need for our *Ingress* spec, list the *IngressClasses* in the cluster:



```bash
➜ candidate@ckad5601:~$ k get ingressclass
NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       2m3s
```

So the class is `traefik`. Without any *Ingress* resource configured, the controller responds with 404:



```bash
➜ candidate@ckad5601:~$ curl http://titan.galaxy.mine:30080
404 page not found
```

But the 404 is still a good sign for us because it means the Traefik Ingress Controller is working.

 

###### **Create the Ingress**

If we have a look at the existing *Services* then we see one runs on port `80` and the other on `8080`:

```bash
➜ candidate@ckad5601:~$ k -n titan get svc
NAME   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
app1   ClusterIP   10.107.202.195   <none>        80/TCP     2m12s
app2   ClusterIP   10.105.12.121    <none>        8080/TCP   2m11s
```

Now we can create the *Ingress*:



```bash
➜ candidate@ckad5601:~$ vim 12.yaml
```

```yaml
# ckad5601:/home/candidate/12.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: titan-ing
  namespace: titan
spec:
  ingressClassName: traefik    # discovered above
  rules:
  - http:
      paths:
      - path: /app1            # first path
        pathType: Prefix
        backend:
          service:
            name: app1         # direct to K8s service port 80
            port:
              number: 80
      - path: /app2            # second path
        pathType: Prefix
        backend:
          service:
            name: app2
            port:
              number: 8080     # app2 Service listens on 8080, not 80
```

```bash
➜ candidate@ckad5601:~$ k apply -f 12.yaml
ingress.networking.k8s.io/titan-ing created
```

 

###### **Verify**

```bash
➜ candidate@ckad5601:~$ k -n titan get ingress
NAME        CLASS     HOSTS   ADDRESS          PORTS   AGE
titan-ing   traefik   *       192.168.100.11   80      6s


➜ candidate@ckad5601:~$ curl http://titan.galaxy.mine:30080/app1
hello from app1


➜ candidate@ckad5601:~$ curl http://titan.galaxy.mine:30080/app2
hello from app2
```

Both paths route through the Traefik Ingress Controller to the correct backend *Service*.

# Checks

- Ingress titan-ing exists in namespace titan
- Ingress uses IngressClass traefik
- Path /app1 returns app1 response via the controller
- Path /app2 returns app2 response via the controller

