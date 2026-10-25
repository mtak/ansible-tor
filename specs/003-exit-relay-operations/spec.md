# Feature Specification: Exit Relay Operations and Policy Review

**Feature Branch**: `004-exit-relay-operations`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "GitHub issue #7: Review tor03's exit policy (ports 53, 80, 443, 993, 995, 1194, 11371) and operating readiness. Confirm each port is intentional and reachable; document abuse notice handling and provider escalation; verify reverse DNS/WHOIS identify the exit relay where supported and confirm host dedication/provider support. Acceptance: policy rationale, response process, and provider records are checked and documented."

## Clarifications

### Session 2026-10-25

- Q: If the review finds a port unjustified or unreachable, should this issue change tor03's active exit policy, or document a recommendation for separate approval? → A: Document findings and recommend changes for separate approval.
- Q: Should the abuse response procedure include a response time target? → A: Document intake and escalation steps without response timing.
- Q: If provider evidence contains private account details or correspondence, should the repository keep a sanitized summary while originals stay in the provider account? → A: Record only a status, without an evidence reference.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review allowed exit services (Priority: P1)

An operator reviews each port in tor03's configured exit policy, decides whether the service is intentionally allowed, records its rationale, and checks direct reachability from tor03 to the intended service.

**Why this priority**: The policy defines which outbound services Tor users can access and is the central subject of issue #7.

**Independent Test**: Review the seven listed ports individually and verify that each has an intentional-use explanation and a recorded direct connection result from tor03 to an endpoint offering the intended service.

**Acceptance Scenarios**:

1. **Given** tor03's configured exit policy, **When** an operator reviews ports 53, 80, 443, 993, 995, 1194, and 11371, **Then** each port has a documented purpose and an explicit keep-or-change decision.
2. **Given** the documented policy decisions, **When** the operator checks each permitted service directly from tor03, **Then** the record identifies the destination, transport, outcome, and date, including failures or checks that could not be completed. A direct node-level check is sufficient for this review; an end-to-end Tor-client test is not required.

### User Story 2 - Handle exit abuse notices (Priority: P1)

An operator receiving an abuse notice can identify how to assess it, respond to the reporter, and escalate relevant cases to the hosting provider.

**Why this priority**: A clear response process helps operators handle complaints consistently and meet provider requirements.

**Independent Test**: A reviewer follows the documented process from receipt of a sample notice through triage, response, and provider escalation decision without needing undocumented operator knowledge.

**Acceptance Scenarios**:

1. **Given** an abuse notice about traffic from tor03, **When** the operator follows the documented process, **Then** the process identifies where the notice is received, what information is assessed, how a response is sent, and what information must not be collected or retained.
2. **Given** a notice that requires provider involvement, **When** the operator reaches the escalation step, **Then** the process identifies the provider contact route, the evidence to include, and how the escalation outcome is recorded.

### User Story 3 - Verify hosting and network identity (Priority: P2)

An operator verifies that public network records identify tor03 as an exit relay where supported, and confirms that the host is dedicated and the provider permits and supports exit relay operation.

**Why this priority**: Accurate public records and confirmed provider support reduce avoidable disputes and operational surprises.

**Independent Test**: A reviewer checks the recorded reverse DNS, WHOIS or equivalent registration records, host dedication status, and provider readiness statuses, with each item marked verified, not supported, unavailable, or requiring follow-up.

**Acceptance Scenarios**:

1. **Given** the public address or addresses assigned to tor03, **When** the operator checks reverse DNS and applicable registration records, **Then** the result and evidence are documented, including when a record type is unsupported or unavailable.
2. **Given** the current hosting arrangement, **When** the operator checks dedication and provider terms or written confirmation, **Then** the repository records the result status, check date, and any non-sensitive follow-up for whether the host is dedicated and exit relay operation is allowed and supported.

### Edge Cases

- A port is configured but cannot be reached during the check; its status and follow-up action are recorded rather than inferred from configuration.
- A protocol or port is unavailable from the check location; the result identifies the limitation and does not claim the service is unreachable generally.
- Reverse DNS, WHOIS, or another public record is unsupported or does not allow a relay identity; the record states this and identifies any available alternative.
- Provider terms are ambiguous or no written confirmation is available; provider readiness remains unverified until evidence is obtained.
- An abuse notice contains personal data; the response process limits handling to information needed to assess and answer the operational complaint, consistent with the project's data-minimization principle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The review MUST cover each configured tor03 exit port: 53, 80, 443, 993, 995, 1194, and 11371.
- **FR-002**: For every reviewed port, the record MUST state its intended service, policy rationale, keep-or-change decision, destination and transport of a direct connection check from tor03, result, and check date. A direct node-level check is sufficient; an end-to-end Tor-client test is not required.
- **FR-003**: The review MUST identify policy changes or follow-up actions needed when a port's purpose or reachability cannot be confirmed; proposed changes to the active exit policy MUST be documented for separate approval and rollout.
- **FR-004**: The abuse response procedure MUST describe notice intake, triage, response steps, recordkeeping, and criteria for contacting the hosting provider; it MUST NOT set a response time target.
- **FR-005**: The abuse response procedure MUST limit stored information to what is necessary to handle the operational notice and MUST NOT introduce collection of specific Tor user activity.
- **FR-006**: Provider escalation guidance MUST identify the contact route, the operational evidence to provide, and how the outcome and any required action are recorded.
- **FR-007**: Reverse DNS and applicable WHOIS or equivalent registration records MUST be checked for the exit relay identity, and the result and supporting evidence MUST be documented.
- **FR-008**: The hosting arrangement MUST be checked for dedicated-host status and provider permission and support for Tor exit relay operation; the resulting status, check date, and any non-sensitive follow-up MUST be documented without copying private provider correspondence or account details into the repository or linking to that evidence.
- **FR-009**: Each external check MUST distinguish verified, not supported, unavailable, and unresolved results so the record does not imply confirmation without evidence.

### Key Entities *(include if data involved)*

- **Exit policy review**: A dated review of each allowed port, its purpose, rationale, decision, and reachability evidence.
- **Abuse notice**: An operational complaint received about traffic associated with the exit relay and the minimal handling record needed for triage and response.
- **Provider readiness status**: A dated status for dedicated-host status, provider permission, and provider support, with non-sensitive follow-up when needed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 7 configured exit ports have an individually recorded rationale, decision, direct connection result from tor03 to an intended service endpoint, and check date.
- **SC-002**: A maintainer unfamiliar with the current response practices can identify the intake route, next action, and escalation decision for a sample abuse notice within 10 minutes using the documented procedure alone.
- **SC-003**: Reverse DNS, applicable registration records, host dedication, and provider support each have a dated status, with unsupported or unavailable items clearly identified; provider readiness may include a non-sensitive follow-up, and confidential provider materials are checked outside the repository.
- **SC-004**: A reviewer can distinguish conclusions supported by shareable evidence from statuses based on confidential provider materials or unresolved follow-up, without private evidence details or references appearing in repository documentation.

## Assumptions

- Issue #7 and the repository's current `tor_exit_ports` list define the scope of the initial policy review.
- The existing policy is the starting point for review; this specification does not presume that any port should be retained or removed.
- Operators can access the hosting provider account or contact route and the public network records needed for the checks; any unavailable access is recorded as unresolved.
- Provider readiness documentation records the result status, check date, and any non-sensitive follow-up; private provider correspondence, account details, and references to that evidence remain outside repository documentation.
- A direct connection check from tor03 to an intended service endpoint is sufficient reachability evidence for this review; an end-to-end Tor-client test is not required.
- The resulting operational record belongs in repository documentation and should be updated when policy, provider arrangements, or response procedures change. Abuse response guidance documents the handling process without promising response timing.
- Findings and proposed changes to the deployed exit policy are documented for separate explicit approval and rollout; this work does not itself change the active policy.
