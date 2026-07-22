package kubernetes.admission

# Deny Pods that run privileged containers.
deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Privileged pods are not allowed: container %v", [container.name])
}
