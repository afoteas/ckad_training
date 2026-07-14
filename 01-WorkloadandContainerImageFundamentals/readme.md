# Workload and Container Image Fundamentals

This module focuses on practical Kubernetes and container fundamentals used in real delivery workflows and CKAD-style practice.

## What You Learn

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
