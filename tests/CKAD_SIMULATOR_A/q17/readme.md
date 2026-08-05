# Tags

[Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers) 

# Question

Solve this question on instance: `ssh ckad5601`

 

The *Deployment* YAML at `/course/17/test-init-container.yaml` spins up a single nginx *Pod* serving files from an empty mounted volume. Add an *InitContainer* to it:

1. Name `init-con`, image `busybox:1`
2. Mounts the same volume as the nginx container
3. Writes `check this out!` into `index.html` at the root of that volume

Test with `curl`.

# Answer


```bash
➜ ssh ckad5601


➜ candidate@ckad5601:~$ cp /course/17/test-init-container.yaml 17.yaml


➜ candidate@ckad5601:~$ vim 17.yaml
```

Add the *InitContainer*:


```yaml
# ckad5601:/home/candidate/17.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: mars
spec:
  replicas: 1
  selector:
    matchLabels:
      id: test-init-container
  template:
    metadata:
      labels:
        id: test-init-container
    spec:
      volumes:
      - name: web-content
        emptyDir: {}
      initContainers:                                  # initContainer start
      - name: init-con
        image: busybox:1
        command: ['sh', '-c', 'echo "check this out!" > /tmp/web-content/index.html']
        volumeMounts:
        - name: web-content
          mountPath: /tmp/web-content                  # initContainer end
      containers:
      - image: nginx:1-alpine
        name: nginx
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80
```

Then we create the *Deployment*:



```bash
➜ candidate@ckad5601:~$ k -f 17.yaml create
deployment.apps/test-init-container created
```

Finally we test the configuration:



```bash
➜ candidate@ckad5601:~$ k -n mars get pod -o wide
NAME                                  READY   STATUS    RESTARTS   AGE   IP          ...
test-init-container-...-xxxxx         1/1     Running   0          15s   10.0.0.67   ...


➜ candidate@ckad5601:~$ curl 10.0.0.67
check this out!
```

Beautiful.

# Checks

- Deployment exists and replicas ready
- Deployment has new initcontainer
- Initcontainer has correct image
- Pod responds via http
- Pod http response contains correct text

