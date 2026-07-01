## Initial

```
docker build -t afoteas/python-web-app:v1.0 .
docker tag afoteas/python-web-app:v1.0 ghcr.io/afoteas/python-web-app:v1.0
docker push ghcr.io/afoteas/python-web-app:v1.0

docker run --rm aquasec/trivy:latest image --severity HIGH,CRITICAL afoteas/python-web-app:v1.0 
```

## Rolling Updates

```
docker pull nginx:1.21.1
kubectl create deployment webserver --image=nginx:1.21.1 --replicas=3
kubectl get deployment webserver


kubectl get pods -l app=webserver
kubectl delete deployment webserver

kubectl set image deployment/webserver nginx=nginx:1.25.5
kubectl rollout status deployment/webserver
kubectl get rs -l app=webserver
kubectl rollout history deployment/webserver
```