# Tags

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap) [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap) 

# Question

Solve this question on instance: `ssh ckad9043`


*Deployment* `web-moon` in *Namespace* `moon` mounts a *ConfigMap* that doesn't exist yet.

Create *ConfigMap* `configmap-web-moon-html` containing the content of `/course/15/web-moon.html` under data key `index.html`.

Test with `curl` that the nginx *Pods* serve the file.

# Answer

Let's check the existing *Pods*:

```bash
➜ ssh ckad9043

➜ candidate@ckad9043:~$ k -n moon get pod
NAME                        READY   STATUS              RESTARTS   AGE
secret-handler              1/1     Running             0          55m
web-moon-847496c686-2rzj4   0/1     ContainerCreating   0          33s
web-moon-847496c686-9nwwj   0/1     ContainerCreating   0          33s
web-moon-847496c686-cxdbx   0/1     ContainerCreating   0          33s
web-moon-847496c686-hvqlw   0/1     ContainerCreating   0          33s
web-moon-847496c686-tj7ct   0/1     ContainerCreating   0          33s


➜ candidate@ckad9043:~$ k -n moon describe pod web-moon-847496c686-2rzj4
...
Warning  FailedMount  31s (x7 over 63s)  kubelet  MountVolume.SetUp failed for volume "html-volume" : configmaps "configmap-web-moon-html" not found
```

Good so far, now let's create the missing *ConfigMap*. It's important to set the key to `index.html`:

```bash
➜ candidate@ckad9043:~$ k -n moon create configmap configmap-web-moon-html --from-file=index.html=/course/15/web-moon.html
configmap/configmap-web-moon-html created
```

This should create a *ConfigMap* with YAML like:


```yaml
# kubectl -n moon get configmap configmap-web-moon-html -oyaml
apiVersion: v1
data:
  index.html: |           # notice the key index.html, this will be the filename when mounted
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Web Moon Webpage</title>
    </head>
    <body>
    This is some great content.
    </body>
    </html>
kind: ConfigMap
metadata:
  name: configmap-web-moon-html
  namespace: moon
```

After waiting a bit or deleting/recreating (`k -n moon rollout restart deploy web-moon`) the *Pods* we should see:

```bash
➜ candidate@ckad9043:~$ k -n moon get pod
NAME                        READY   STATUS    RESTARTS   AGE
secret-handler              1/1     Running   0          59m
web-moon-847496c686-2rzj4   1/1     Running   0          4m28s
web-moon-847496c686-9nwwj   1/1     Running   0          4m28s
web-moon-847496c686-cxdbx   1/1     Running   0          4m28s
web-moon-847496c686-hvqlw   1/1     Running   0          4m28s
web-moon-847496c686-tj7ct   1/1     Running   0          4m28s
```

Looking much better. Finally we check if the nginx returns the correct content:

```bash
➜ candidate@ckad9043:~$ k -n moon get pod -o wide
NAME                        READY   STATUS    RESTARTS   AGE    IP           ...
web-moon-847496c686-2rzj4   1/1     Running   0          5m     10.44.0.78   ...
...
```

Then use one IP to test the configuration:

```bash
➜ candidate@ckad9043:~$ curl 10.44.0.78
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Web Moon Webpage</title>
</head>
<body>
This is some great content.
</body>
```

For debugging or further checks we could find out more about the *Pods* volume mounts:

```bash
➜ candidate@ckad9043:~$ k -n moon describe pod web-moon-847496c686-2rzj4 | grep -A2 Mounts:
    Mounts:
      /usr/share/nginx/html from html-volume (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-rvzcf (ro)
```

And check the mounted folder content:



```bash
➜ candidate@ckad9043:~$ k -n moon exec web-moon-847496c686-2rzj4 -- find /usr/share/nginx/html
/usr/share/nginx/html
/usr/share/nginx/html/..2026_06_04_10_05_56.336284411
/usr/share/nginx/html/..2026_06_04_10_05_56.336284411/index.html
/usr/share/nginx/html/..data
/usr/share/nginx/html/index.html
```

Here it was important that the file will have the name `index.html` and not the original one `web-moon.html` which is controlled through the *ConfigMap* data key.

# Checks

- ConfigMap exists
- ConfigMap correctly defined
- Deployment running

