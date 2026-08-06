# Tags

[Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies) [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy)

# Question

Solve this question on instance: `ssh ckad6422`

 

In *Namespace* `cedar` two *Deployments* `api` and `frontend` are exposed via *Services*.

Create a *NetworkPolicy* `np1` that restricts egress from `frontend`:

1. Allow traffic to `api` *Pods*
2. Allow port 53 for DNS

Verify with: `curl www.google.com` and `curl api:2222` from a *Pod* of *Deployment* `frontend`.

# Answer

> ℹ️ For learning NetworkPolicies check out [https://editor.cilium.io](https://editor.cilium.io). But you're not allowed to use it during the exam.

First we get an overview:

```sh
➜ ssh ckad6422

➜ candidate@ckad6422:~$ k -n cedar get all
NAME                            READY   STATUS    RESTARTS   AGE
pod/api-5979b95578-gktxp        1/1     Running   0          57s
pod/api-5979b95578-lhcl5        1/1     Running   0          57s
pod/frontend-789cbdc677-c9v8h   1/1     Running   0          57s
pod/frontend-789cbdc677-npk2m   1/1     Running   0          57s
pod/frontend-789cbdc677-pl67g   1/1     Running   0          57s
pod/frontend-789cbdc677-rjt5r   1/1     Running   0          57s
pod/frontend-789cbdc677-xgf5n   1/1     Running   0          57s


NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/api        ClusterIP   10.3.255.137   <none>        2222/TCP   37s
service/frontend   ClusterIP   10.3.255.135   <none>        80/TCP     57s
...
```

(Optional) Both ClusterIPs are routable from the controlplane, so we can curl them directly to verify the *Services* work before applying the policy:

```sh
➜ candidate@ckad6422:~$ curl -s 10.3.255.135:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...

➜ candidate@ckad6422:~$ curl -s 10.3.255.137:2222
<html><body><h1>It works!</h1></body></html>
```

Then we use any `frontend` *Pod* and check if it can reach external names and the `api` *Service*:

```sh
➜ candidate@ckad6422:~$ k -n cedar exec frontend-789cbdc677-c9v8h -- curl -s www.google.com
<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head>
...

➜ candidate@ckad6422:~$ k -n cedar exec frontend-789cbdc677-c9v8h -- curl -s api:2222
<html><body><h1>It works!</h1></body></html>
...
```

We see *Pods* of `frontend` can reach the `api` and external names.

```sh
➜ candidate@ckad6422:~$ vim 13_np1.yaml
```

Now we head to [https://kubernetes.io/docs](https://kubernetes.io/docs), search for *NetworkPolicy*, copy the example code and adjust it to:

```yaml
# ckad6422:/home/candidate/13_np1.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: cedar
spec:
  podSelector:
    matchLabels:
      id: frontend          # label of the pods this policy should be applied on
  policyTypes:
  - Egress                  # we only want to control egress
  egress:
  - to:                     # 1st egress rule
    - podSelector:            # allow egress only to pods with api label
        matchLabels:
          id: api
  - ports:                  # 2nd egress rule
    - port: 53                # allow DNS UDP
      protocol: UDP
    - port: 53                # allow DNS TCP
      protocol: TCP
```

Notice that we specify two egress rules in the YAML above. If we specify multiple egress rules then these are connected using a logical OR. So in the example above we do:



```
allow outgoing traffic if
  (destination pod has label id:api) OR ((port is 53 UDP) OR (port is 53 TCP))
```

Let's have a look at example code which wouldn't work in our case:

```yaml
# this example does not work in our case
...
  egress:
  - to:                     # 1st AND ONLY egress rule
    - podSelector:            # allow egress only to pods with api label
        matchLabels:
          id: api
    ports:                  # STILL THE SAME RULE but just an additional selector
    - port: 53                # allow DNS UDP
      protocol: UDP
    - port: 53                # allow DNS TCP
      protocol: TCP
```

In the YAML above we only specify one egress rule with two selectors. It can be translated into:

```
allow outgoing traffic if
  (destination pod has label id:api) AND ((port is 53 UDP) OR (port is 53 TCP))
```

Apply the correct policy:

```sh
➜ candidate@ckad6422:~$ k -f 13_np1.yaml create
networkpolicy.networking.k8s.io/np1 created
```

And try again, external is not working any longer:

```sh
➜ candidate@ckad6422:~$ k -n cedar exec frontend-789cbdc677-c9v8h -- curl -s www.google.de
^C


➜ candidate@ckad6422:~$ k -n cedar exec frontend-789cbdc677-c9v8h -- curl -s -m 5 www.google.de:80
curl: (28) Operation timed out
command terminated with exit code 1
```

Internal connection to `api` work as before:

```sh
➜ candidate@ckad6422:~$ k -n cedar exec frontend-789cbdc677-c9v8h -- curl -s api:2222
```

# Checks

- NetworkPolicy exists
- Deployments api and frontend exist with replicas ready
- Deployment frontend cannot reach internet
- Deployment frontend can resolve DNS
- Deployment frontend can reach deployment api

