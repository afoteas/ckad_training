# Tags

[Helm Docs](https://helm.sh/docs)

# Question

Solve this question on instance: `ssh ckad6422`

Team Birch needs some Helm operations performed in *Namespace* `birch`:

1. Delete release `internal-issue-report-apiv1`
2. Upgrade release `internal-issue-report-apiv2` to any newer version of chart `killershell/nginx` available
3. Install a new release `internal-issue-report-apache` of chart `killershell/apache`. The *Deployment* should have two replicas, set these via Helm-values during install
4. There seems to be a broken release, stuck in `pending-install` state. Find it and delete it 

# Answer

*Helm Chart*: Kubernetes YAML template-files combined into a single package, *Values* allow customisation

*Helm Release*: Installed instance of a *Chart*

*Helm Values*: Allow to customise the YAML template-files in a *Chart* when creating a *Release*

###### **Step 1**

First we should delete the required release:

```bash
➜ ssh ckad6422


➜ candidate@ckad6422:~$ helm -n birch ls
NAME                          NAMESPACE  ...   STATUS            CHART
internal-issue-report-apiv1   birch      ...   deployed          nginx-18.1.14
internal-issue-report-apiv2   birch      ...   deployed          nginx-18.1.14
internal-issue-report-app     birch      ...   deployed          nginx-18.1.14
internal-issue-report-daniel  birch      ...   pending-install   nginx-18.1.14


➜ candidate@ckad6422:~$ helm -n birch uninstall internal-issue-report-apiv1
release "internal-issue-report-apiv1" uninstalled


➜ candidate@ckad6422:~$ helm -n birch ls
NAME                          NAMESPACE  ...   STATUS            CHART
internal-issue-report-apiv2   birch      ...   deployed          nginx-18.1.14
internal-issue-report-app     birch      ...   deployed          nginx-18.1.14
internal-issue-report-daniel  birch      ...   pending-install   nginx-18.1.14
```

###### **Step 2**

Next we need to upgrade a release, for this we could first list the charts of the repo:

```bash
➜ candidate@ckad6422:~$ helm repo list
NAME            URL                  
killershell     http://localhost:6000


➜ candidate@ckad6422:~$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "killershell" chart repository
Update Complete. ⎈Happy Helming!⎈


➜ candidate@ckad6422:~$ helm search repo nginx --versions
NAME                CHART VERSION    DESCRIPTION                                       
killershell/nginx   18.2.0       NGINX Open Source is a...
killershell/nginx   18.1.15      NGINX Open Source is a...
killershell/nginx   18.1.14      NGINX Open Source is a...
killershell/nginx   13.0.0       NGINX Open Source is a...
```

Here we see that two newer chart versions are available. But the question only requires us to upgrade to any newer chart version available, so we can simply run:



```bash
➜ candidate@ckad6422:~$ helm -n birch upgrade internal-issue-report-apiv2 killershell/nginx
Release "internal-issue-report-apiv2" has been upgraded. Happy Helming!
NAME: internal-issue-report-apiv2
LAST DEPLOYED: Mon Aug 25 14:21:24 2026
NAMESPACE: birch
STATUS: deployed
REVISION: 2
TEST SUITE: None


➜ candidate@ckad6422:~$ helm -n birch ls
NAME                            NAMESPACE   ...   STATUS            CHART
internal-issue-report-apiv2     birch     ...   deployed          nginx-18.2.0  
internal-issue-report-app       birch     ...   deployed          nginx-18.1.14
internal-issue-report-daniel    birch     ...   pending-install   nginx-18.1.14
```

Looking good!

> ℹ️ Also check out `helm rollback` for undoing a helm rollout/upgrade

 ###### **Step 3**

Now we're asked to install a new release, with a customised values setting. For this we first list all possible value settings for the chart, we can do this via:



```bash
➜ candidate@ckad6422:~$ helm show values killershell/apache
global:
  imageRegistry: ""
  imagePullSecrets: []
kubeVersion: ""
nameOverride: ""
fullnameOverride: ""
commonLabels: {}
commonAnnotations: {}
extraDeploy: []
image:
  registry: docker.io
  repository: httpd
  pullPolicy: IfNotPresent
  pullSecrets: []
  debug: false
replicaCount: 1
revisionHistoryLimit: 10
podAffinityPreset: ""
podAntiAffinityPreset: soft
extraPodSpec: {}
```

Or to parse YAML and render with colors:

```bash
➜ candidate@ckad6422:~$ helm show values killershell/apache | yq e
global:
  imageRegistry: ""
  imagePullSecrets: []
kubeVersion: ""
nameOverride: ""
fullnameOverride: ""
commonLabels: {}
commonAnnotations: {}
extraDeploy: []
image:
  registry: docker.io
  repository: httpd
  pullPolicy: IfNotPresent
  pullSecrets: []
  debug: false
replicaCount: 1
revisionHistoryLimit: 10
podAffinityPreset: ""
podAntiAffinityPreset: soft
extraPodSpec: {}
```

This can be a huge list for larger Helm charts. We should find the setting `replicaCount: 1` on top level. This means we can run:

```bash
➜ candidate@ckad6422:~$ helm -n birch install internal-issue-report-apache killershell/apache --set replicaCount=2
NAME: internal-issue-report-apache
LAST DEPLOYED: Mon Aug 25 14:23:38 2026
NAMESPACE: birch
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

If we would also need to set a value on a deeper level, for example `image.debug`, we could run:

```bash
➜ candidate@ckad6422:~$ helm -n birch install internal-issue-report-apache killershell/apache \
  --set replicaCount=2 \
  --set image.debug=true
```

Install done, let's verify what we did:

```bash
➜ candidate@ckad6422:~$ helm -n birch ls
NAME                            NAMESPACE   ...   STATUS            CHART
internal-issue-report-apache    birch     ...   deployed          apache-11.2.20    
internal-issue-report-apiv2     birch     ...   deployed          nginx-18.2.0  
internal-issue-report-app       birch     ...   deployed          nginx-18.1.14
internal-issue-report-daniel    birch     ...   pending-install   nginx-18.1.14


➜ candidate@ckad6422:~$ k -n birch get deploy internal-issue-report-apache
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
internal-issue-report-apache   2/2     2            2           64s
```

We see a healthy deployment with two replicas!


###### **Step 4**

Find and delete the broken release:

```bash
➜ candidate@ckad6422:~$ helm -n birch ls
NAME                            NAMESPACE   ...  STATUS            CHART
internal-issue-report-apache    birch     ...  deployed          apache-11.2.20
internal-issue-report-apiv2     birch     ...  deployed          nginx-18.2.0
internal-issue-report-app       birch     ...  deployed          nginx-18.1.14
internal-issue-report-daniel    birch     ...  pending-install   nginx-18.1.14

➜ candidate@ckad6422:~$ helm -n birch uninstall internal-issue-report-daniel
release "internal-issue-report-daniel" uninstalled
```

Thank you Helm for making our lives easier! (Till something breaks)

# Checks

- Deleted Helm release internal-issue-report-apiv1
- Upgraded Helm release internal-issue-report-apiv2
- Installed Helm release internal-issue-report-apache
- Helm release internal-issue-report-apache has two replicas
- Deleted broken Helm release

