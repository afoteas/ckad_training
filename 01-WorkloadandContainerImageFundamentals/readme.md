# Workload and Container Image Fundamentals

This module focuses on practical Kubernetes and container fundamentals used in real delivery workflows and CKAD-style practice.

## CKAD Exam Relevance

**Priority: High — start here.** This module covers core CKAD skills: choosing the right workload type (Pod, Deployment, Job, CronJob, DaemonSet), rolling updates and rollout status, multicontainer patterns (init, sidecar, adapter), volumes, and PVC mounts. The exam frequently asks you to create or fix Deployments, mount storage, and design multi-container Pods under time pressure. Image building lessons are lighter on the exam but help you understand `image`, `imagePullPolicy`, and registry workflows. Master lessons 04–09 before moving on.

## Lesson CKAD Relevance

| # | Lesson | Priority | Why it matters for CKAD |
|---|--------|----------|-------------------------|
| 01 | OCI-Compliant Images Using Dockerfile Best Practices | Low | Image building is rarely hands-on; understand `FROM`, layers, and small images conceptually |
| 02 | Creating Multistage Builds and Slimming Images | Low | Good practice; exam may reference image size or security but won't ask you to write a Dockerfile |
| 03 | Pushing and Scanning Images in a Registry | Low | Registry workflows are background knowledge; `imagePullPolicy` is more exam-relevant |
| 04 | Choose the Right Workload Resources | **High** | Must know when to use Pod, Deployment, Job, CronJob, DaemonSet, StatefulSet |
| 05 | Implementing Rolling Updates with Deployments | **High** | Rolling updates, `kubectl rollout status`, and Deployment strategy fields are common tasks |
| 06 | Multicontainer Pod Patterns | **High** | Init, sidecar, and adapter patterns appear frequently in exam scenarios |
| 07 | Deploying a Sidecar Logging Pattern | **High** | Hands-on sidecar Pod design is a classic CKAD exercise |
| 08 | Volumes in Pods | **High** | emptyDir, ConfigMap, Secret, and volume mount syntax are core skills |
| 09 | Creating a PVC and Mounting It in a Deployment | **High** | Creating PVCs and mounting persistent storage in Deployments is regularly tested |


- build OCI-compliant images with Dockerfile best practices
- optimize image size and build speed with multistage builds
- push and scan images in a registry
- choose the right workload resources for application behavior
- perform rolling updates safely with Deployments
- design and run multicontainer pod patterns
- implement a sidecar logging pattern
- understand Pod volume types and lifecycle behavior
- create and mount PVC-backed storage in a Deployment

## Lesson Order

1. `01-OCI-CompliantImagesUsingDockerfileBestPractices`
2. `02-CreatingMultistageBuildsAndSlimmingImages`
3. `03-PushingAndScanningImagesInARegistry`
4. `04-ChooseTheRightWorkloadResources`
5. `05-ImplementingRollingUpdatesWithDeployments`
6. `06-MulticontainerPodPatterns`
7. `07-DeployingASidecarLoggingPattern`
8. `08-VolumesInPods`
9. `09-CreatingAPVCAndMountingItInADeployment`

## Suggested Flow

1. Start with image standards and optimization.
2. Move to registry workflows and scanning.
3. Continue with Kubernetes workload design and rollout behavior.
4. Continue with multicontainer and sidecar patterns.
5. Finish with Pod volume models and persistent storage integration.

## Objectives

- outline best practices for crafting small, secure container images
- create a multistage Dockerfile to reduce image size and surface area
- push images to a registry and run vulnerability scans
- compare Pods, Deployments, Jobs, CronJobs, and DaemonSets based on workload requirements
- implement rolling update and monitor rollout status
- describe multicontainer Pod design patterns, including sidecar, init, and adapter patterns with use cases
- deploy a sidecar container to collect and stream logs
- differentiate between EmptyDir, ConfigMap, Secret, PersistentVolumeClaim (PVC), and ephemeral volumes used in Kubernetes Pods
- create a PersistentVolumeClaim (PVC) and mount it in an application Deployment
