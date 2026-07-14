# Multicontainer Pod Patterns

This lesson introduces when and why to run multiple containers inside a single Pod.

## Why Multicontainer Pods

Use a multicontainer Pod when processes are tightly coupled and must share:

- network namespace (same Pod IP)
- mounted volumes
- scheduling locality on the same node

This helps separate concerns while keeping components operationally close.

## Core Patterns

### 1) Sidecar

Runs alongside the main app for the full Pod lifecycle.

Common use cases:

- log shipping
- metrics exporting
- service mesh proxying

### 2) Init Container

Runs before app containers start, then exits.

Common use cases:

- fetch startup config
- wait for dependency readiness
- perform migration/bootstrap checks

### 3) Adapter

Transforms protocols or data formats between app and external systems.

Common use cases:

- convert custom metrics format to Prometheus format
- translate legacy output into standardized APIs

## Choosing the Right Pattern

- Choose sidecar for continuous helper functionality.
- Choose init for one-time preconditions before app startup.
- Choose adapter for translation between incompatible interfaces.

## Operational Trade-Off

Multicontainer Pods improve modularity, but increase observability and debugging scope because more processes run in one unit.

## Summary

Sidecar, init, and adapter patterns are foundational Kubernetes design tools for building modular, resilient application Pods while preserving shared runtime context where required.
