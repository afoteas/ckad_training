
package main

import (
	"context"
	"fmt"
	"log"
	"path/filepath"
	"time"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

func main() {
	fmt.Println("🚀 Kubernetes Go Client Demo")
	fmt.Println("=============================\n")

	// Build kubeconfig path
	kubeconfig := filepath.Join(homedir.HomeDir(), ".kube", "config")
	fmt.Printf("Using kubeconfig: %s\n\n", kubeconfig)

	// Build config from kubeconfig file
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		log.Fatalf("Error building kubeconfig: %v", err)
	}

	// Create Kubernetes clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Error creating clientset: %v", err)
	}

	fmt.Println("✅ Successfully connected to Kubernetes cluster\n")

	// Create a namespace for our demo
	namespace := "go-demo"
	ctx := context.Background()

	fmt.Printf("Creating namespace: %s\n", namespace)
	ns := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: namespace,
		},
	}
	_, err = clientset.CoreV1().Namespaces().Create(ctx, ns, metav1.CreateOptions{})
	if err != nil {
		fmt.Printf("⚠️  Namespace may already exist: %v\n", err)
	} else {
		fmt.Println("✅ Namespace created\n")
	}

	// Create a Pod
	fmt.Println("Creating Pod: demo-nginx")
	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "demo-nginx",
			Namespace: namespace,
			Labels: map[string]string{
				"app":        "nginx",
				"created-by": "go-client",
			},
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:  "nginx",
					Image: "nginx:1.25",
					Ports: []corev1.ContainerPort{
						{
							ContainerPort: 80,
							Protocol:      corev1.ProtocolTCP,
						},
					},
				},
			},
			RestartPolicy: corev1.RestartPolicyAlways,
		},
	}

	createdPod, err := clientset.CoreV1().Pods(namespace).Create(ctx, pod, metav1.CreateOptions{})
	if err != nil {
		log.Fatalf("Error creating pod: %v", err)
	}
	fmt.Printf("✅ Pod created: %s\n\n", createdPod.Name)

	// Create a second Pod
	fmt.Println("Creating Pod: demo-redis")
	pod2 := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "demo-redis",
			Namespace: namespace,
			Labels: map[string]string{
				"app":        "redis",
				"created-by": "go-client",
			},
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:  "redis",
					Image: "redis:7",
					Ports: []corev1.ContainerPort{
						{
							ContainerPort: 6379,
							Protocol:      corev1.ProtocolTCP,
						},
					},
				},
			},
			RestartPolicy: corev1.RestartPolicyAlways,
		},
	}

	createdPod2, err := clientset.CoreV1().Pods(namespace).Create(ctx, pod2, metav1.CreateOptions{})
	if err != nil {
		log.Fatalf("Error creating pod: %v", err)
	}
	fmt.Printf("✅ Pod created: %s\n\n", createdPod2.Name)

	// Wait a moment for pods to be scheduled
	fmt.Println("Waiting 3 seconds for pods to be scheduled...")
	time.Sleep(3 * time.Second)

	// List all Pods in the namespace
	fmt.Printf("\n📋 Listing all Pods in namespace '%s':\n", namespace)
	fmt.Println("=========================================")

	pods, err := clientset.CoreV1().Pods(namespace).List(ctx, metav1.ListOptions{})
	if err != nil {
		log.Fatalf("Error listing pods: %v", err)
	}

	fmt.Printf("Found %d pod(s):\n\n", len(pods.Items))

	for i, pod := range pods.Items {
		fmt.Printf("%d. Pod Name: %s\n", i+1, pod.Name)
		fmt.Printf("   Status: %s\n", pod.Status.Phase)
		fmt.Printf("   Node: %s\n", pod.Spec.NodeName)
		fmt.Printf("   Pod IP: %s\n", pod.Status.PodIP)
		fmt.Printf("   Labels: %v\n", pod.Labels)
		fmt.Printf("   Containers:\n")
		for _, container := range pod.Spec.Containers {
			fmt.Printf("     - %s (image: %s)\n", container.Name, container.Image)
		}
		fmt.Println()
	}

	// List Pods with label selector
	fmt.Println("\n🔍 Listing Pods with label 'app=nginx':")
	fmt.Println("=======================================")

	labelSelector := "app=nginx"
	nginxPods, err := clientset.CoreV1().Pods(namespace).List(ctx, metav1.ListOptions{
		LabelSelector: labelSelector,
	})
	if err != nil {
		log.Fatalf("Error listing pods with label selector: %v", err)
	}

	fmt.Printf("Found %d pod(s) with label '%s':\n\n", len(nginxPods.Items), labelSelector)
	for _, pod := range nginxPods.Items {
		fmt.Printf("- %s (Status: %s)\n", pod.Name, pod.Status.Phase)
	}

	// Get a specific Pod
	fmt.Println("\n🔎 Getting specific Pod: demo-nginx")
	fmt.Println("====================================")

	specificPod, err := clientset.CoreV1().Pods(namespace).Get(ctx, "demo-nginx", metav1.GetOptions{})
	if err != nil {
		log.Fatalf("Error getting pod: %v", err)
	}

	fmt.Printf("Pod: %s\n", specificPod.Name)
	fmt.Printf("Created: %s\n", specificPod.CreationTimestamp)
	fmt.Printf("UID: %s\n", specificPod.UID)
	fmt.Printf("Status: %s\n", specificPod.Status.Phase)

	fmt.Println("\n✅ Demo completed successfully!")
	fmt.Println("\nTo view the pods with kubectl, run:")
	fmt.Printf("  kubectl get pods -n %s\n", namespace)
	fmt.Println("\nTo cleanup, run:")
	fmt.Printf("  kubectl delete namespace %s\n", namespace)
}
