package main

# Deny privileged containers.
deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Container '%s' is running in privileged mode, which is a security risk", [container.name])
}

# Deny containers without CPU/memory limits.
deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container '%s' must define resource limits", [container.name])
}

# Deny containers without CPU/memory requests.
deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  not container.resources.requests
  msg := sprintf("Container '%s' must define resource requests", [container.name])
}

# Deny images using the :latest tag (or no tag).
deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  endswith(container.image, ":latest")
  msg := sprintf("Container '%s' must not use the ':latest' image tag", [container.name])
}

# Deny host network usage.
deny[msg] {
  input.kind == "Pod"
  input.spec.hostNetwork == true
  msg := "hostNetwork is not allowed as it bypasses network isolation"
}
