# Feature Specification: Unbound Resolver Security and Exit DNS Monitoring

**Feature Branch**: `003-unbound-dns-monitoring`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Issue #11: Verify effective Unbound listeners/access boundaries, DNSSEC, QNAME minimization, outbound source address, and package updates. Repository points resolv.conf at local Unbound but does not establish these effective settings. Add actionable alerts for Tor exit DNS timeout/error metrics. Acceptance: resolver settings and boundaries are verified, DNS protections enabled as intended, and exit DNS alerting works."

## Clarifications

### Session 2026-10-25
- Q: Which clients should each managed node’s Unbound resolver accept recursive DNS requests from? → A: Allow requests from the node itself only.
- Q: Should each node use one explicitly chosen address for its outgoing DNS queries, or should it use whichever address the operating system selects? → A: Let the operating system choose the outgoing address and verify the selected address.
- Q: Where should operators receive Tor exit DNS alerts? → A: The existing monitoring service that collects the Tor metrics.
- Q: Should operators be alerted for any single DNS timeout or error, or only when failures continue past a threshold? → A: Alert only when failures continue beyond a configurable threshold for more than one hour.
- Q: How long should DNS timeouts and errors remain healthy before an active alert is resolved? → A: Resolve after the first healthy monitoring check.
- Q: Since the current Tor exporter has no DNS timeout/error metrics, how should the plan supply this signal? → A: Use per-node aggregate Unbound statistics.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verify resolver security posture (Priority: P1)

As an operator, I need to know that each managed node's running resolver has the intended listeners, client access boundaries, DNS protections, and outbound source address, so DNS requests follow the node's security policy.

**Why this priority**: A local resolver address alone does not show which interfaces or clients the resolver serves, or whether protective resolver behavior is active.

**Independent Test**: Inspect the effective resolver state on every targeted node and confirm it matches the documented policy; verify allowed clients can resolve names and disallowed clients cannot use the resolver.

**Acceptance Scenarios**:

1. **Given** a managed node has been configured, **When** an operator reviews its effective resolver settings, **Then** the resolver listens for recursive requests on the node itself only, and its DNSSEC behavior, QNAME minimization behavior, and operating-system-selected outbound source address are verified.
2. **Given** a process on the managed node sends a DNS query, **When** the resolver receives it, **Then** the resolver accepts and processes it using the required protections.
3. **Given** a client other than the managed node itself sends a DNS query to a managed node, **When** it requests recursive service, **Then** the resolver refuses the request.
4. **Given** a DNSSEC-protected answer is invalid, **When** the resolver evaluates it, **Then** the resolver does not return it as a valid answer.

### User Story 2 - Keep resolver packages current (Priority: P2)

As an operator, I need resolver packages on managed nodes to follow the repository's package update policy, so known fixes are available consistently across nodes.

**Why this priority**: Current packages are part of the resolver's ongoing security posture and the project policy requires managed packages to use the latest available versions.

**Independent Test**: Compare each managed node's installed resolver package with the latest version available from its configured supported distribution repositories after the normal update process.

**Acceptance Scenarios**:

1. **Given** a supported package update is available, **When** the repository's normal update process is applied, **Then** each targeted node installs the latest available resolver package version.
2. **Given** a node cannot reach its configured package repositories, **When** package currency is checked, **Then** the node is identified as not verified current rather than being reported as current.

### User Story 3 - Act on Tor exit DNS failures (Priority: P1)

As an operator, I need actionable notification when DNS timeouts or errors affect Tor exit service, so I can investigate resolver or network failures before they persist unnoticed.

**Why this priority**: DNS is required for exit traffic, and collected metrics provide value only if sustained failures lead to a clear operational response.

**Independent Test**: Introduce or simulate a sustained exit DNS timeout/error condition and confirm an operator receives an alert that identifies the affected exit node, failure type, and response guidance; confirm recovery clears the alert.

**Acceptance Scenarios**:

1. **Given** an exit node's rate of DNS SERVFAIL responses exceeds the configured failure threshold, **When** the condition persists for more than one hour, **Then** an actionable alert identifies the affected node and resolver failure signal and provides a next step for investigation through the existing monitoring service that collects the Tor metrics.
2. **Given** an alert is active, **When** the DNS signal returns within its healthy range at the next monitoring check, **Then** the alert is resolved.
3. **Given** metrics are absent or cannot be evaluated, **When** monitoring checks exit DNS health, **Then** the condition is surfaced as a monitoring failure instead of being treated as healthy.

### Edge Cases

- Effective settings differ from the repository's intended settings because of a default, drop-in file, or unmanaged override.
- Multiple interfaces or address families are active while only a subset should serve clients.
- A node has no usable route for outbound DNS traffic, or its selected source address changes after a route change.
- DNSSEC validation fails for a legitimate response because of a trust or time problem; the operator can distinguish this from an invalid signed answer.
- An exit node stops exporting DNS metrics; missing telemetry must not suppress a health alert.
- Brief DNS failures lasting one hour or less must not trigger an alert; the failure threshold is configurable.
- A package repository is unavailable or has no newer package; currency reporting must distinguish these conditions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST configure Unbound to accept recursive DNS requests from the managed node itself only.
- **FR-002**: The system MUST make the effective resolver listeners and client access boundaries verifiable on every targeted node.
- **FR-003**: The resolver MUST refuse recursive DNS requests from clients other than the managed node itself.
- **FR-004**: The resolver MUST validate DNSSEC responses and MUST apply QNAME minimization to upstream lookups.
- **FR-005**: The system MUST verify the source address selected by the node's operating system for outbound resolver queries and identify nodes with no usable route.
- **FR-006**: Resolver package management MUST follow the repository policy of installing the latest available version from configured supported repositories.
- **FR-007**: The system MUST use per-node aggregate Unbound statistics, including SERVFAIL responses and exporter availability, to evaluate resolver health for each monitored Tor exit node without collecting query-level data.
- **FR-008**: The system MUST alert operators when an exit node's DNS SERVFAIL rate exceeds the configured failure threshold continuously for more than one hour.
- **FR-009**: Each exit DNS alert MUST identify the affected node, the resolver failure signal, the observed condition, and an actionable investigation step.
- **FR-010**: The system MUST deliver exit DNS alerts through the existing monitoring service that collects the Tor metrics.
- **FR-011**: The system MUST detect unavailable or unevaluable exit DNS health signals and report them as monitoring failures.
- **FR-012**: The system MUST resolve an exit DNS alert at the first monitoring check where the relevant signal is healthy.
- **FR-013**: Resolver and alerting behavior MUST be expressible as repository-managed, reproducible configuration and applicable to all targeted nodes.

### Key Entities

- **Resolver posture**: The effective listeners, permitted client networks, DNSSEC and QNAME minimization behavior, outbound source address, and package currency for a managed node.
- **Exit DNS health signal**: Per-node aggregate Unbound timeout, error, or telemetry-availability state used to evaluate resolver health for a Tor exit node; it does not identify individual queries or users.
- **DNS alert**: An operator-facing condition identifying an affected exit node, failure type, observed condition, and response guidance, with active and resolved states.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of targeted nodes have their effective resolver listeners, client boundaries, DNSSEC state, QNAME minimization state, outbound source address, and package currency verified against the approved policy.
- **SC-002**: In policy checks, 100% of permitted test clients can use the resolver and 100% of denied test clients are refused recursive service.
- **SC-003**: All DNSSEC-invalid test answers are rejected, and all configured QNAME minimization checks pass on every targeted node.
- **SC-004**: A DNS SERVFAIL rate that exceeds the configured failure threshold continuously for more than one hour produces an actionable alert within one monitoring evaluation interval after the one-hour period.
- **SC-005**: Loss of exit DNS telemetry is surfaced as a monitoring failure within one monitoring evaluation interval.
- **SC-006**: An alert resolves at the first monitoring evaluation after the signal returns to its healthy range.
- **SC-007**: Operators can identify the affected node, DNS failure type, and next investigation step from each alert without consulting a separate runbook.

## Assumptions

- The feature applies to all managed Tor nodes that run Unbound and to all Tor exit nodes whose DNS health is monitored.
- Listener addresses and the failure threshold will be defined from repository inventory and operator policy during planning; the alert condition must persist for more than one hour. The operating system selects each node's outbound source address, which the system verifies rather than pinning to an operator-selected value. Alerts resolve on the first healthy monitoring check.
- Existing Unbound exporter metrics provide an aggregate SERVFAIL signal and exporter availability, but do not identify upstream timeouts separately. Sustained SERVFAIL is used as a broad resolver-failure signal; alerting does not attribute failures to individual Tor requests or claim a specific cause.
- Package currency is measured against the configured supported Debian or Ubuntu LTS repositories, consistent with the project constitution.
- The existing monitoring service that collects Tor metrics is available to evaluate and deliver alerts to operators.
