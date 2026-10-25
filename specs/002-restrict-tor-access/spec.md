# Feature Specification: Restrict Tor Control and Metrics Access

**Feature Branch**: `002-restrict-tor-access`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: GitHub issue #5 — Harden Tor ControlPort and MetricsPort access. Bind control to localhost or a Unix socket and enable authentication; restrict metrics binding/policy to Prometheus scraper addresses. Confirm exporter and scrape functionality after the change. Acceptance: unauthorized remote clients cannot control Tor or read metrics; authorized monitoring continues to work; effective access policy is documented.

## User Scenarios & Testing

### User Story 1 - Protect Tor Control Access (Priority: P1)

As an operator, I need Tor's control interface to be available only to trusted local automation with authentication, so remote or unauthenticated clients cannot change Tor behavior.

**Why this priority**: Unauthorized control can compromise relay operation and is the most sensitive exposure described by the issue.

**Independent Test**: Attempt control access from an unauthorized remote client and from the authorized local exporter and Nyx operator; the former is denied while both authorized local clients can authenticate and perform their required operations.

**Acceptance Scenarios**:

1. **Given** a client outside the node's authorized local control context, **When** it attempts to connect to the control interface, **Then** it cannot establish control access.
2. **Given** the Tor exporter on a managed node, **When** it connects using the configured authentication, **Then** it can retrieve the Tor information needed for monitoring.
3. **Given** an operator running Nyx locally on a managed node, **When** Nyx connects using the configured authentication, **Then** it can inspect and manage Tor through the control interface.

### User Story 2 - Preserve Authorized Metrics Scraping (Priority: P1)

As a monitoring operator, I need the Prometheus scraper to continue collecting Tor metrics while other clients are denied access.

**Why this priority**: The protection is only operationally successful if authorized monitoring remains available across managed nodes.

**Independent Test**: Scrape the metrics interface from the configured Prometheus scraper and attempt the same request from a client outside the allowed set.

**Acceptance Scenarios**:

1. **Given** a request from an authorized Prometheus scraper, **When** it requests Tor metrics, **Then** it receives the expected metrics successfully.
2. **Given** a request from an address outside the allowed scraper set, **When** it requests Tor metrics, **Then** access is denied.

### User Story 3 - Understand the Effective Policy (Priority: P2)

As a maintainer, I need the access rules and authorized monitoring sources documented, so I can review and operate the deployment consistently.

**Why this priority**: Clear policy makes the restrictions auditable and helps prevent accidental loss of monitoring during future changes.

**Independent Test**: A maintainer can locate the project documentation and identify which clients may use control and metrics access and what authorization is required.

**Acceptance Scenarios**:

1. **Given** the project's operational documentation, **When** a maintainer reviews the Tor access policy, **Then** the control access boundary, authentication expectation, and metrics scraper allowlist are stated.

### Edge Cases

- When an unauthorized source attempts access, the request is rejected without interrupting Tor service or authorized scrapes.
- When the authorized scraper address changes, monitoring remains unavailable to other sources until the allowlist is deliberately updated, and the documented policy can be updated with it.
- When authentication is missing or invalid for a control request, the request is rejected.
- When a Tor service is restarted with the restricted policy, the configured exporter can reconnect and resume collection.

## Requirements

### Functional Requirements

- **FR-001**: Tor control access MUST be limited to the local node through localhost or a local socket.
- **FR-002**: Tor control access MUST require authentication; unauthenticated or invalidly authenticated requests MUST be rejected.
- **FR-003**: Tor metrics access MUST be limited to the configured Prometheus scraper source addresses.
- **FR-004**: Requests for Tor metrics from sources outside the configured allowlist MUST be denied.
- **FR-005**: The authorized Tor exporter MUST continue to authenticate to the control interface and collect the information it requires.
- **FR-006**: Nyx running locally for an authorized operator MUST continue to authenticate to the control interface and provide its Tor inspection and management functions.
- **FR-007**: The authorized Prometheus scraper MUST continue to retrieve Tor metrics after the restrictions are applied.
- **FR-008**: Project operational documentation MUST state the effective control and metrics access policy, including the authorized monitoring sources and local Nyx operator access.

### Key Entities

- **Authorized control client**: A local service permitted to use Tor's control interface after authentication.
- **Nyx operator**: An authorized administrator using the local Tor terminal interface to inspect and manage the daemon.
- **Metrics scraper source**: A Prometheus scraper address permitted to retrieve Tor metrics.
- **Access policy**: The documented and enforced boundaries defining permitted control and metrics clients.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of tested control connection attempts from unauthorized remote clients are denied.
- **SC-002**: 100% of tested control requests without valid authentication are denied, while the local Nyx operator and exporter retain their authorized functions.
- **SC-003**: 100% of test scrapes from configured Prometheus sources return Tor metrics, while 100% of test scrapes from outside the allowlist are denied.
- **SC-004**: Maintainers can identify the authorized control context and metrics scraper addresses from project documentation without inspecting runtime configuration.

## Assumptions

- The existing Prometheus Tor exporter is the authorized local control client and must retain the access it needs.
- Nyx is an authorized local administrative control client and must retain the access it needs for Tor inspection and management.
- The set of permitted metrics sources is determined by the deployment's existing Prometheus scrape configuration and inventory; this feature documents and restricts to that set.
- The policy applies consistently to all managed Tor relay and exit nodes.
- Routine deployment and service recovery continue to be performed through the repository's existing Ansible-managed configuration.
