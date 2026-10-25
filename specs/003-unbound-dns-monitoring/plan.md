# Implementation Plan: Unbound Resolver Security and Exit DNS Monitoring

**Branch**: `codex/issue-11-unbound-dns-monitoring` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification in `specs/003-unbound-dns-monitoring/spec.md` (issue #11)

## Summary

Make Unbound's node-local recursive boundary, DNSSEC validation, and QNAME minimization explicit and verifiable on all managed nodes while allowing operating-system route selection to choose outbound DNS source addresses. Reuse per-node aggregate Unbound statistics for resolver failure alerting. Keep a Prometheus rule bundle in this repository for import into the existing external monitoring service; fire only after a configured SERVFAIL threshold remains exceeded for more than one hour and resolve on the first healthy evaluation. SERVFAIL is a broad resolver-failure signal and cannot identify upstream timeout as the unique cause.

## Technical Context

**Language/Version**: Ansible YAML and Jinja templates; no application language/runtime is added.

**Primary Dependencies**: Ansible; supported Debian or Ubuntu LTS packages for Unbound; the existing Let's Encrypt Unbound exporter v0.4.1; the existing external Prometheus-based monitoring service. The pinned atx Tor exporter v0.4 does not provide DNS error/timeout metrics and is not the source for these alerts.

**Storage**: No feature-owned database. Prometheus retains aggregate time series according to its existing external policy. No query names, client addresses, or individual DNS requests are collected.

**Testing**: Ansible syntax check and check mode; `unbound-checkconf`; runtime listener, access-boundary, DNSSEC, QNAME-minimization, and route-selection checks; exporter metric inspection; external Prometheus rule validation and rule tests. This repository defines no mandatory CI/test gate.

**Target Platform**: Managed Tor nodes running supported Debian or Ubuntu LTS releases.

**Project Type**: Ansible infrastructure configuration with a Prometheus alert-rule bundle for an externally managed monitoring service.

**Performance Goals**: Preserve normal resolver behavior without a new service or intentional query path. A qualifying SERVFAIL condition becomes firing after more than one hour and one rule evaluation; recovery occurs on the first healthy evaluation.

**Constraints**: Recursive DNS must be loopback-only; OS routing selects the outbound source address; Ansible-managed Unbound packages follow the latest-available package policy; monitoring data remains aggregate; alert delivery uses the existing external Prometheus notification route. The numeric SERVFAIL threshold and external rule-import path must be confirmed during implementation.

**Scale/Scope**: Applies to every active `all-servers` inventory node for resolver posture and every active `tor-exit` node for exit DNS alerting. The current inventory has three active managed nodes and one active exit (`tor03`); scope follows inventory changes.

## Constitution Check

### Pre-Design Gate

- **I. Preserve Service Boundaries — PASS.** Resolver settings belong to `roles/unbound`; exporter collection remains in `roles/prometheus-exporters`; Prometheus alert definitions are kept as a separate, importable monitoring artifact because this repository has no Prometheus server role. This boundary matches the feature's explicit need to alert from the existing external metrics service.
- **II. Keep Nodes Reproducible and Replaceable — PASS.** Resolver settings and node-side exporter behavior remain Ansible-managed. The alert rule source is versioned in the repository; external loading is a documented integration dependency.
- **III. Respect Tor Project Guidance — PASS.** The feature does not change Tor exit policies or Tor protocol settings. It improves local resolver protection consistent with Tor's documented DNSSEC and QNAME-minimization intent.
- **IV. Minimize Stored User Information — PASS.** Only per-node aggregate Unbound counters and exporter availability are used. No QNAME, client identity, or per-query log is collected.
- **V. Keep Operational Changes Understandable — PASS.** No monitoring service is added. The cross-boundary rule artifact exists only because the existing external service must evaluate and deliver the alert.
- **Operational policy — PASS.** Supported node OS releases remain Debian or Ubuntu LTS; Unbound package management retains the latest-available policy.

No constitution violation requires an exception.

## Phase 0: Research

See [research.md](research.md). Research resolves the configuration choices and records the current telemetry limits: the Tor exporter has no DNS metrics; Unbound's current exporter supplies aggregate SERVFAIL and scrape-availability signals but not a distinct upstream-timeout counter. SERVFAIL can indicate a resolver failure caused by an upstream timeout, DNSSEC failure, or another cause, so alert names and operator guidance must not claim a unique cause. The external Prometheus rule import and numeric SERVFAIL threshold are implementation-time operational inputs, not blockers to the design artifact.

## Phase 1: Design and Contracts

- [Data model](data-model.md) defines resolver posture, per-node aggregate health signals, and DNS alert state without user-level DNS data.
- [Prometheus alerting contract](contracts/prometheus-alerting.md) defines input series, target identity, firing/recovery semantics, missing-telemetry behavior, labels, and validation requirements.
- [Quickstart](quickstart.md) provides runnable resolver, package, exporter, and monitoring validation scenarios.
- The external Prometheus rule file is planned under `monitoring/prometheus/tor-exit-dns.rules.yml`; the exact existing service import path and target label must be confirmed when implementing.

## Project Structure

### Documentation (this feature)

```text
specs/003-unbound-dns-monitoring/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    └── prometheus-alerting.md
```

### Source Code (repository root)

```text
roles/
└── unbound/
    ├── tasks/main.yml
    ├── templates/resolver-policy.conf
    └── handlers/main.yml

monitoring/
└── prometheus/
    └── tor-exit-dns.rules.yml     # repository-managed rule bundle imported externally
```

No changes are planned to the Tor exit policy, user-facing services, or node firewall ports. The resolver's loopback binding enforces the local-only request boundary independently of broad UDP firewall acceptance.

**Structure Decision**: Keep node resolver settings with the Unbound role. Reuse the existing Unbound exporter without changing its service configuration; it already exposes the aggregate SERVFAIL and exporter-health metrics required by this design. Store alert rules in a narrowly scoped Prometheus directory because the external service consumes Prometheus rules while this repository does not deploy that service. Do not add an API, database, metrics server, or Alertmanager.

## Post-Design Constitution Check

- **Service ownership and boundaries — PASS.** Each node-side setting remains in its owning role; the Prometheus rule bundle is an external-consumer artifact and adds no service deployment.
- **Reproducibility — PASS.** Node configuration and the rule source are versioned. The external monitoring owner must import the rule bundle through the existing process.
- **Tor guidance and privacy — PASS.** No Tor protocol configuration or query-level telemetry is added. SERVFAIL is presented as a broad resolver signal.
- **Understandable operations — PASS.** The run guide defines how to validate the node-side state and the external alert behavior. External rule loading is called out as an operational dependency.
- **OS and package policy — PASS.** No OS or package policy changes are proposed.

No constitution violation requires an exception.
