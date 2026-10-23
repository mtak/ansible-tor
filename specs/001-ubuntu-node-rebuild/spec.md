# Feature Specification: Rebuild TakTor Nodes on Ubuntu 26.04 LTS

**Feature Branch**: `001-ubuntu-node-rebuild`

**Created**: 2026-10-23

**Status**: Draft

**Input**: User decision to move the active Tor nodes to Ubuntu 26.04 LTS and restore Ansible management.

## Clarifications

### Session 2026-10-23
- Q: Should the constitution permit Ubuntu LTS as a managed node operating system alongside Debian? → A: Yes; Debian and Ubuntu LTS are both allowed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rebuild and Manage the Active Nodes (Priority: P1)

As the Tor operator, I need all active nodes rebuilt on Ubuntu 26.04 LTS and
reprovisioned from the repository so that I can maintain the relays through
repeatable Ansible runs again.

**Why this priority**: The current Debian 10 nodes run Python 3.7, which cannot
execute modules from the current Ansible controller. Rebuilding is the selected
recovery path.

**Independent Test**: Starting from Ubuntu 26.04 LTS on the three active
inventory hosts can be reached and fully configured from the repository.

**Acceptance Scenarios**:

1. **Given** Ubuntu 26.04 LTS on an active inventory host, **When** the
   repository configuration is applied, **Then** the host is manageable by Ansible
   and receives the services and configuration assigned to its inventory role.
2. **Given** the active inventory, **When** all three hosts are rebuilt, **Then**
   `tor01` and `tor02` return as non-exit relays and `tor03` returns as an exit relay.

---

### User Story 2 - Preserve Relay Identity During Routine Rebuild (Priority: P1)

As the Tor operator, I need routine rebuilds to retain each relay's long-term identity
so that the relays keep their existing fingerprints and do not restart their network
reputation from zero.

**Why this priority**: Tor relays take time to build traffic and reputation. The
operator has chosen to preserve identity keys for routine recovery and rotate them
when compromise is suspected.

**Independent Test**: Before a node disk is erased, its identity backup can be
restored in a secure recovery environment and its resulting fingerprint matches the
recorded inventory fingerprint.

**Acceptance Scenarios**:

1. **Given** no suspicion of compromise and a verified backup, **When** a relay is
   rebuilt, **Then** its restored identity produces the same fingerprint recorded
   for that host.
2. **Given** a node is suspected to be compromised, **When** it is rebuilt, **Then**
   its old identity keys are not restored and new identity keys are provisioned.
3. **Given** any node's key backup cannot be decrypted or does not match its recorded
   fingerprint, **When** a rebuild is prepared, **Then** that node's disk is not
   erased until the recovery source is resolved.

---

### User Story 3 - Retain Existing Relay and Host Services (Priority: P2)

As the Tor operator, I need the rebuilt nodes to retain their existing relay, exit,
DNS, firewall, access, and monitoring behavior so that the rebuild does not change
how the network is operated.

**Why this priority**: The repository manages more than Tor itself; its service
roles and monitoring provide the complete operating environment for each node.

**Independent Test**: After configuration, role-specific Tor policies, Unbound,
firewall rules, SSH access, exporters, and cluster reporting match the repository's
declared inventory and variables.

**Acceptance Scenarios**:

1. **Given** a rebuilt relay node, **When** its configuration is applied, **Then**
   Tor remains non-exit, its relay ports and bandwidth policy match its variables,
   and the Tor and node exporters are available.
2. **Given** a rebuilt exit node, **When** its configuration is applied, **Then**
   Tor applies the configured exit port allowlist and blocked hosts, and its
   exporters are available.
3. **Given** any rebuilt node, **When** its services are checked, **Then** Unbound,
   the configured firewall, SSH access, and reporting behave as before the rebuild.

### Edge Cases

- If an identity backup is missing, undecryptable, or has the wrong fingerprint,
  stop before erasing that node's disk.
- If compromise is suspected, do not restore that node's backed-up identity keys.
- If a provider rebuild changes a node's public address, update DNS and relevant
  configuration before expecting Tor to pass its external reachability check.
- If a node fails provisioning, report the failed host and leave the deployment
  status clear; do not report the whole fleet as recovered.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The active inventory hosts (`tor01`, `tor02`, and `tor03`) MUST be
  provisionable on Ubuntu 26.04 LTS (Resolute).
- **FR-002**: Managed node state MUST remain reproducible from repository inventory,
  variables, playbooks, and service roles.
- **FR-003**: Reprovisioning MUST preserve the existing role boundaries for shared
  host setup, SSH, firewall, entropy service, DNS, Tor, exporters, and reporting.
- **FR-004**: `tor01` and `tor02` MUST operate as non-exit relays, and `tor03` MUST
  operate as an exit relay with its configured blocked hosts and allowed ports.
- **FR-005**: Rebuilt nodes MUST retain the configured relay ports, bandwidth limits,
  host-specific values, and monitoring metrics.
- **FR-006**: Monitoring and reporting MUST remain limited to aggregate system health
  and Tor operational metrics; no specific user information may be added.
- **FR-007**: Routine recovery MUST restore each node's long-term Tor identity keys
  from a verified, encrypted backup. A suspected compromise MUST use new identity
  keys instead.
- **FR-008**: A node's disk MUST NOT be erased until its required identity recovery
  material is verified as decryptable and matched to that node's expected
  fingerprint.
- **FR-009**: Ansible MUST be able to manage all three rebuilt hosts using the
  project's supported controller, without the Python 3.7 module parsing failure
  found on the current nodes.
- **FR-010**: Ansible-managed packages MUST continue to use the latest available
  versions, consistent with the project policy.
- **FR-011**: The migration MUST replace the Debian Buster Tor package source with a
  repository suite compatible with Ubuntu 26.04, using the distribution codename.
- **FR-012**: The rebuild process MUST make the expected service outage clear before
  the provider erases a node's data.

### Key Entities

- **Node**: An active host identified by inventory hostname, relay/exit role,
  network address, host variables, and expected Tor fingerprint.
- **Tor identity backup**: The encrypted long-term RSA and Ed25519 identity key
  files associated with one node and its expected fingerprint.
- **Service role**: A repository-owned responsibility for configuring shared host
  setup or a particular node service.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 3 of 3 active inventory hosts pass Ansible connectivity and complete
  configuration without a Python interpreter error.
- **SC-002**: All 3 hosts return to their assigned Tor role, and each routine rebuild
  reports the same identity fingerprint as its pre-rebuild record.
- **SC-003**: All 3 hosts report Tor, Unbound, node exporter, and Tor exporter as
  active after configuration; the report role completes for the rebuilt fleet.
- **SC-004**: The two relay nodes reject exit traffic, while the exit node applies
  the configured blocked-host and allowed-port policy.
- **SC-005**: Tor's external reachability self-test succeeds for each rebuilt node.
- **SC-006**: No key material is emitted in logs or stored unencrypted in the
  repository during backup, verification, or restoration.

## Assumptions

- The provider supplies an Ubuntu 24.04 LTS image; each node is release-upgraded to
  Ubuntu 26.04 LTS before Ansible configures its services. The assigned public
  address is expected to remain unchanged; if it changes, DNS and configuration
  must be updated as part of the rebuild.
- Current inventory and host variables remain the source of truth for node roles,
  ports, bandwidth policies, hostnames, and expected fingerprints.
- A secure, decryptable recovery copy of each node's required long-term identity keys
  will be established before its disk is erased.
- The constitution permits supported Debian or Ubuntu LTS releases as managed node
  operating systems. Ubuntu 26.04 LTS is the final target OS for this migration.
- A future move from Ubuntu 26.04 to Ubuntu 28.04 is outside this feature's scope.
