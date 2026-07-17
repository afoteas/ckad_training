# Distributed Tracing with OpenTelemetry and Jaeger

Distributed tracing assigns a unique trace ID to every request entering the system. The ID propagates across all service hops, and each service records its work as a span. The result is a complete timeline showing exactly where time was spent.

## Why Tracing

Logs and metrics are insufficient alone:

| Tool | Answers |
|---|---|
| Metrics | *what* — service X is slow overall |
| Logs | *where* — this error occurred inside service X |
| Traces | *why* — request took 190 ms: 12 ms in frontend, 48 ms in checkout, 130 ms in payment |

Without tracing, a 500 ms end-to-end latency is invisible as a breakdown across services.

## OpenTelemetry

OpenTelemetry is the vendor-neutral CNCF standard for generating and collecting telemetry (traces, metrics, logs). It provides:

- **SDKs** for Java, Python, Go, .NET, and other languages
- **Auto-instrumentation** — activate tracing with minimal or no code changes
- **Vendor neutrality** — instrument once, switch backends without rewriting application code

Before OpenTelemetry, every tracing tool (Zipkin, Jaeger) had its own proprietary SDK, creating vendor lock-in.

## Jaeger

Jaeger is the CNCF-hosted backend for storing, querying, and visualizing traces. Its waterfall diagram shows:

- the sequence of service calls
- duration of each span
- parallel vs sequential operations
- the primary latency contributor at a glance

## Architecture

```
App (OpenTelemetry SDK)
    ↓ OTLP
OpenTelemetry Collector
    ↓
Jaeger Backend (storage + UI)
```

## Trace Structure

```
TraceID: abc123
├── frontend     12ms
├── checkout     48ms
└── payment     130ms
─────────────────────
Total:          190ms   ← payment is the bottleneck
```

Each row is a **span**. The total is the sum of the critical path.

## Considerations

- traces require in-process instrumentation (the app must propagate the trace context) — unlike metrics which can often be collected externally
- trace volume is enormous (one entry per request); implement **sampling** (e.g., 1 in 100 requests) to control storage costs
- Jaeger must be sized for the retention period and expected throughput
- tracing complements, not replaces, metrics and logs — all three are needed for full observability
