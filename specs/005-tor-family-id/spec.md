# Feature Specification: One Tor Relay Family

**Feature Branch**: `005-tor-family-id`

**Created**: 2026-11-06

**Status**: Draft

**Input**: Resolve issues #8 and #18 by declaring all active Tor relays managed by this project as one operator family. Today these are tor01, tor02, and tor03; future active relays join the same family. Use the supported FamilyID mechanism, deploy from a reusable local family key outside Git, remove obsolete MyFamily configuration, verify publication, and document membership maintenance. The operator stores the key as base64 text in a password manager without unlocking it for routine deployments.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publish one operator family (Priority: P1)

As a relay operator, I want every active relay I operate to advertise the same family so Tor clients can avoid using two of them in one circuit.

**Why this priority**: Correct family publication is the purpose of issues #8 and #18 and protects circuit diversity.

**Independent Test**: Deploy the family configuration to the current active relays, then check their published network records for the same family identifier.

**Acceptance Scenarios**:

1. **Given** tor01, tor02, and tor03 are active and use a Tor version supporting family identifiers, **when** the family configuration is applied, **then** all three publish valid membership in the same family.
2. **Given** an active relay has received the family configuration, **when** its published network record is inspected, **then** its family identifier matches the other active relays and no obsolete family declaration is published for it.

---

### User Story 2 - Add or retire a relay (Priority: P2)

As a relay operator, I want active relay membership to follow the managed relay inventory so a new relay joins the existing family and a retired relay does not remain in active configuration.

**Why this priority**: Membership changes should not require editing every other relay or leave stale identities behind.

**Independent Test**: Add a prospective relay to the active inventory in a dry run and verify it receives the same family identity without changing the family settings of existing relays.

**Acceptance Scenarios**:

1. **Given** a new relay is added to the active managed inventory, **when** it is configured with the operator's family key, **then** it advertises the same family identifier as existing relays.
2. **Given** a relay is removed from active inventory, **when** the remaining relays are configured, **then** their family configuration contains no reference to the retired relay's identity.

---

### User Story 3 - Deploy with a local key (Priority: P3)

As a relay operator, I want routine deployments to use an available local key so I do not have to unlock my password manager on every run.

**Why this priority**: Deployments should be convenient without exposing the shared secret.

**Independent Test**: Run a deployment with a valid local key, then repeat with a missing or mismatched key and check that family configuration remains unchanged.

**Acceptance Scenarios**:

1. **Given** the local family key is available and matches the configured family identifier, **when** a routine deployment runs, **then** it can complete without accessing the password manager.
2. **Given** the local key is absent, unreadable, or does not match the configured identifier, **when** deployment starts, **then** it stops with an actionable error before changing any relay's family configuration and does not reveal key material.

### Edge Cases

- A relay runs a version that does not support the chosen family mechanism: deployment must stop before changing its family configuration.
- The active inventory is empty or a relay lacks the shared key: deployment must not claim successful family publication.
- A relay is temporarily offline during rollout: completion remains unverified until that relay publishes matching membership.
- The family secret appears in logs, version control, or deployment output: the deployment fails the secret-handling requirement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The deployment MUST assign one shared operator family to every active Tor relay managed by this project, including both non-exit and exit relays and future active relays.
- **FR-002**: The deployment MUST use a family mechanism supported by the deployed Tor version and MUST stop before a family change on any targeted relay whose version lacks support.
- **FR-003**: Every active relay MUST use the same family secret and matching public family identifier; a missing, unreadable, or mismatched secret MUST prevent family configuration changes on the targeted relays.
- **FR-004**: Routine deployments MUST be possible from a persistent local copy of the secret outside version control, without requiring password-manager access on each run.
- **FR-005**: The family secret MUST remain absent from committed files, public configuration, deployment output, and operational documentation; only the public identifier may appear there.
- **FR-006**: The deployment MUST place the family secret on each active relay with access limited to the relay service account and privileged operators before activating its family configuration.
- **FR-007**: The deployment MUST remove obsolete MyFamily configuration from both relay types and MUST NOT require a list of other relay fingerprints for family membership.
- **FR-008**: The operator MUST be able to verify that every active relay publishes valid membership in the same family, including its server descriptor and client-facing family information, before declaring the migration complete.
- **FR-009**: Operational documentation MUST explain how to supply the persistent local key for deployment, add and retire relays, and verify family membership.
- **FR-010**: A failed or incomplete rollout MUST be reported as such, identifying which active relays have not been verified without exposing the secret.

### Key Entities

- **Active relay**: A Tor relay currently managed for operation by this project; has a unique relay identity and one operator family membership.
- **Operator family**: The set of all active relays controlled by this operator; identified publicly by one shared family identifier.
- **Family secret**: Private material shared by active members to prove family membership; the operator supplies a persistent decoded binary deployment copy while storing its base64 representation in their password manager.
- **Published membership**: Network-visible proof that a relay belongs to the operator family, used to verify that clients can recognize the relationship.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 3 currently active relays publish valid membership in the same family, and 0 active relays publish only the obsolete family mechanism.
- **SC-002**: A newly added active relay can join the existing family without changing the family settings of any existing active relay.
- **SC-003**: 100% of routine deployments with a valid local secret complete without access to the password manager; 100% of deployments with a missing or mismatched secret stop before altering family settings.
- **SC-004**: The operator can identify the membership status of every active relay from published network records and can distinguish verified, pending, and failed publication.
- **SC-005**: An operator following the runbook can complete a dry-run walkthrough for adding a relay without needing undocumented steps.

## Assumptions

- The active family consists of tor01, tor02, and tor03 now; every future active Tor relay managed by this project belongs to the same operator family. Decommissioned hosts are not active members.
- The operator stores the family key as base64 text in a password manager and keeps a persistent decoded binary secret file outside Git for routine deployments. The local file is available on the deployment controller during routine runs.
- The current supported Tor family mechanism is FamilyID. The exact version and publication behavior are verified during planning and again before deployment.
- The existing project constitution allows changes to be applied to all targeted nodes together; a one-node-at-a-time rollout is not required.
- This feature covers relay family membership and key handling for that membership. It does not change relay identity keys, exit policy, or unrelated Tor settings.
