# Tags

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap) [Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations)

# Question

Solve this question on instance: `ssh ckad6422`

*Deployment* `walnut-app` in *Namespace* `walnut` has hardcoded env vars `GREETING` and `TARGET`. Move them into a *ConfigMap*:

1. Create *ConfigMap* `walnut-config` with keys `greeting` and `target` using the existing values
2. Add the annotation `killer.sh/team: walnut` to the *ConfigMap*
3. Update the *Deployment* to read the env vars from the *ConfigMap*

# Answer

 ###### **Investigate**

First we connect and inspect the existing *Deployment* to discover the current values:

```sh
➜ ssh ckad6422

➜ candidate@ckad6422:~$ k -n walnut get deploy walnut-app -oyaml
```
```yaml
# kubectl -n walnut get deploy walnut-app -oyaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: walnut-app
  namespace: walnut
...
spec:
...
  template:
...
    spec:
      containers:
      - args:
        - |
          echo "$GREETING $TARGET" > /usr/share/nginx/html/index.html
          exec nginx -g 'daemon off;'
        command:
        - sh
        - -c
        env:
        - name: GREETING
          value: Very well welcome to
        - name: TARGET
          value: Team Cedar
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
...
```

Current values are `Very well welcome to` and `Team Cedar`. We could also call the *Pod* to see the Nginx answering with them:

```sh
➜ candidate@ckad6422:~$ k -n walnut get pod -owide
NAME                         READY   STATUS   ...   IP         ...
walnut-app-7594c5d8cb-vwrds   1/1     Running  ...   10.32.0.4  ...

➜ candidate@ckad6422:~$ curl 10.32.0.4
Very well welcome to Team Cedar
```

###### **Create the *ConfigMap***

Now we create the *ConfigMap* with those exact values:

```sh
➜ candidate@ckad6422:~$ k -n walnut create configmap walnut-config --from-literal=greeting="Very well welcome to" --from-literal=target="Team Cedar"
configmap/walnut-config created
```

Add the annotation (we could also use `kubectl edit`):


```sh
➜ candidate@ckad6422:~$ k -n walnut annotate configmap walnut-config killer.sh/team=walnut
configmap/walnut-config annotated
```

We check the *ConfigMap*:

```sh
➜ candidate@ckad6422:~$ k -n walnut get configmap walnut-config -oyaml
apiVersion: v1
data:
  greeting: Very well welcome to
  target: Team Cedar
kind: ConfigMap
metadata:
  annotations:
    killer.sh/team: walnut
  name: walnut-config
  namespace: walnut
...
```

###### **Update the *Deployment***

Now edit the *Deployment* and replace the hardcoded values with references to the *ConfigMap*:

```sh
➜ candidate@ckad6422:~$ k -n walnut edit deployment walnut-app
```
```yaml
# kubectl -n walnut edit deployment walnut-app
apiVersion: apps/v1
kind: Deployment
metadata:
  name: walnut-app
  namespace: walnut
...
spec:
...
  template:
...
    spec:
      containers:
      - args:
        - |
          echo "$GREETING $TARGET" > /usr/share/nginx/html/index.html
          exec nginx -g 'daemon off;'
        command:
        - sh
        - -c
        env:
        - name: GREETING
          #value: Very well welcome to    # remove
          valueFrom:                      # add
            configMapKeyRef:              # add
              name: walnut-config          # add
              key: greeting               # add
        - name: TARGET
          #value: Team Cedar              # remove
          valueFrom:                      # add
            configMapKeyRef:              # add
              name: walnut-config          # add
              key: target                 # add
        image: nginx:1-alpine
        imagePullPolicy: IfNotPresent
        name: nginx
...
```

After saving, a new *Pod* rolls out. Optionally we can verify the env vars are visible inside the container and also curl the *Pod* IP:

```sh
➜ candidate@ckad6422:~$ k -n walnut get pod -owide
NAME                         READY   STATUS    RESTARTS   AGE   IP         ...
walnut-app-76cb6699b7-hwqkc   1/1     Running   0          20s   10.32.0.5  ...


➜ candidate@ckad6422:~$ k -n walnut exec -it walnut-app-76cb6699b7-hwqkc -- env
...
NJS_RELEASE=1
ACME_VERSION=0.4.1
GREETING=Very well welcome to
TARGET=Team Cedar
...


➜ candidate@ckad6422:~$ curl 10.32.0.5
Very well welcome to Team Cedar
```

A *ConfigMap* keeps configuration out of the container image and allows for cleaner application configuration.

# Checks

- ConfigMap walnut-config has correct keys
- ConfigMap walnut-config has annotation killer.sh/team=walnut
- Deployment walnut-app exposes both ConfigMap keys as env vars
- Deployment walnut-app has at least one ready replica

