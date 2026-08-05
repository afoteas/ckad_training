# Tags

# Question

There are files to build a container image located at `/course/11/image` on `ckad9043`. The container will run a Golang application which outputs information to stdout. You're asked to perform the following tasks:

 

> ℹ️ Run all Docker commands as user root. Use `sudo docker` or become root with `sudo -i`

 

1. Change the Dockerfile: set ENV variable `SUN_CIPHER_ID` to hardcoded value `5b9c1065-e39d-4a43-a04a-e59bcea3e03f`
2. Build the image using `sudo docker`, tag it `registry.killer.sh:5000/sun-cipher:v1` and push it to the registry
3. Run a container using `sudo docker`, which keeps running detached in the background, named `sun-cipher` using image `registry.killer.sh:5000/sun-cipher:v1`
4. Write the logs your container `sun-cipher` produces into `/course/11/logs` on `ckad9043`
5. Load the container image from `/course/11/container.tar.gz` into the local image store

# Answer

*Dockerfile*: list of commands from which an *Image* can be built

*Image*: binary file which includes all data/requirements to be run as a *Container*

*Container*: running instance of an *Image*

*Registry*: place where we can push/pull *Images* to/from

 

###### **Step 1**

We should probably create a backup:



```bash
➜ ssh ckad9043


➜ candidate@ckad9043:~$ cp /course/11/image/Dockerfile /course/11/image/Dockerfile_bak
```

First we need to change the `/course/11/image/Dockerfile` to:



```dockerfile
# build container stage 1
FROM docker.io/library/alpine:3
WORKDIR /src
COPY . .


# app container stage 2
FROM docker.io/library/alpine:3
COPY --from=0 /src/app app
# CHANGE NEXT LINE
ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f
CMD ["./app"]
```

 

###### **Step 2**

Then we build the image using Docker:


```bash
➜ candidate@ckad9043:~$ cd /course/11/image

➜ candidate@ckad9043:/course/11/image$ sudo docker build -t registry.killer.sh:5000/sun-cipher:v1 .
...
Successfully built 409fde3c5bf9
Successfully tagged registry.killer.sh:5000/sun-cipher:v1


➜ candidate@ckad9043:/course/11/image$ sudo docker image ls
REPOSITORY                           TAG     IMAGE ID       ...
registry.killer.sh:5000/sun-cipher   v1      1568c7ec35e9   ...


➜ candidate@ckad9043:/course/11/image$ sudo docker push registry.killer.sh:5000/sun-cipher:v1
The push refers to repository [registry.killer.sh:5000/sun-cipher]
546b6556c787: Pushed 
02d370f1ff96: Pushed 
9b70e313681f: Pushed 
v1: digest: sha256:1568c7ec35e92c130b9be7752acd06f21c75147267c4c7af6f10e61e886ffffe size: 855
```

There we go, built and pushed.


###### **Step 3**

Now we run a container from the image we just pushed. The `-d` flag detaches it so it keeps running in the background:

```bash
➜ candidate@ckad9043:/course/11/image$ sudo docker run -d --name sun-cipher registry.killer.sh:5000/sun-cipher:v1
1e75b8788a71cde74e7228ff90a4411bc3187cd6833b059a3058dc2e84ad9aab


➜ candidate@ckad9043:/course/11/image$ sudo docker ps
CONTAINER ID   IMAGE                                   ...   STATUS         NAMES
f8199cba792f   registry.killer.sh:5000/sun-cipher:v1   ...   Up 3 seconds   sun-cipher
```

###### **Step 4**

Here we save the container's logs into the requested file:

```bash
➜ candidate@ckad9043:/course/11/image$ sudo docker logs sun-cipher
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 991
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 5007
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 9651
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 6527
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 787
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 4593
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 8889
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 4963
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 3142
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 5273
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 8270
2026/06/10 17:05:12 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 4321
2026/06/10 17:05:22 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 4778
2026/06/10 17:05:32 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 4680
2026/06/10 17:05:42 random number for 5b9c1065-e39d-4a43-a04a-e59bcea3e03f is 9080


➜ candidate@ckad9043:/course/11/image$ sudo docker logs sun-cipher > /course/11/logs
```

###### **Step 5**

It's possible to export container images as an archive, for example using `docker save`. The file `/course/11/container.tar.gz` is such an archive, load it into the local image store:



```bash
➜ candidate@ckad9043:/course/11/image$ sudo docker load -i /course/11/container.tar.gz
Loaded image: sun-static:v1


➜ candidate@ckad9043:/course/11/image$ sudo docker image ls sun-static
REPOSITORY   TAG   IMAGE ID       CREATED       SIZE
sun-static   v1    8b1e78743a03   2 weeks ago   8.5MB
```

The name and tag come from what was recorded in the archive at save time.

# Checks

- Dockerfile has been adjusted
- Docker image built with tag
- Docker image pushed to registry with tag
- Docker container sun-cipher is running
- File /course/11/logs contains the UUID from container logs
- Image sun-static:v1 loaded from archive

