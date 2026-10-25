# Tasks: Unbound Resolver Security and Exit DNS Monitoring

**Input**: Design documents from `specs/003-unbound-dns-monitoring/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story. Separate test tasks are omitted because tests were not requested; each story includes its independent acceptance check.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with another task because it edits a different file and has no dependency on unfinished work.
- **[Story]**: User story associated with the task.
- Every implementation task names its target file path.

## Phase 1: Setup

**Purpose**: Existing Ansible project, inventory, and role structure are already initialized. No setup tasks are needed.

## Phase 2: Foundational

**Purpose**: Existing Unbound and Prometheus exporter roles provide the shared foundation. No new shared component blocks the user stories.

## Phase 3: User Story 1 - Verify resolver security posture (Priority: P1) 🎯 MVP

**Goal**: Configure and verify recursive DNS listeners and access for the managed node itself only, DNSSEC validation, QNAME minimization, and OS-selected outbound source address.

**Independent Test**: Confirm on each targeted node that only enabled loopback addresses accept recursive queries, external clients are refused, valid DNSSEC data resolves, invalid DNSSEC data is rejected, QNAME minimization is active, and outbound DNS uses the route-selected source address.

### Implementation

- [X] T001 [P] [US1] Create `roles/unbound/templates/resolver-policy.conf` with `interface: 127.0.0.1`, `access-control: 127.0.0.0/8 allow`, conditional `interface: ::1` and `access-control: ::1 allow` when IPv6 is enabled, `module-config: "validator iterator"`, the distribution-managed root trust anchor, and `qname-minimisation: yes`; do not set `outgoing-interface`.
- [X] T002 [US1] Update `roles/unbound/tasks/main.yml` to install `resolver-policy.conf` under `/etc/unbound/unbound.conf.d/` with the Ansible `template` module's `validate: unbound-checkconf %s` option, and notify `restart_unbound` when it changes.

**Checkpoint**: The resolver role owns a reproducible node-local-only policy and can apply it independently of the monitoring changes.

## Phase 4: User Story 3 - Act on Tor exit DNS failures (Priority: P1)

**Goal**: Alert through the existing Prometheus-based monitoring service on sustained per-node aggregate Unbound SERVFAILs and missing telemetry, with recovery on the first healthy evaluation.

**Independent Test**: Confirm the external service maps the active exit target, a sustained over-threshold SERVFAIL signal fires after more than one hour, a healthy next evaluation resolves it, and missing exporter telemetry raises a monitoring-failure alert. The notification must identify the node and SERVFAIL signal without claiming a unique cause.

### Implementation

- [ ] T003 [P] [US3] Inspect the existing Prometheus scrape and rule-import configuration with its owner, then record the actual exit-node target labels, rule import path, and threshold value location in `specs/003-unbound-dns-monitoring/contracts/prometheus-alerting.md`.
- [ ] T004 [US3] Review recent `unbound_answer_rcodes_total{rcode="SERVFAIL"}` data to select and record an initial threshold, then add `monitoring/prometheus/tor-exit-dns.rules.yml` with per-exit SERVFAIL-rate alerting that remains over threshold for one hour, a missing/unavailable Unbound-exporter alert, existing severity conventions, node-identifying labels, and cause-agnostic operator guidance; omit firing retention so the first healthy evaluation resolves the alert.
- [X] T005 [US3] Document how to import and verify `monitoring/prometheus/tor-exit-dns.rules.yml` through the existing Prometheus notification path in `ANSIBLE_RUNBOOK.md`, including the external ownership boundary and the fact that SERVFAIL does not prove an upstream timeout.

**Checkpoint**: The repository contains a reviewable alert-rule bundle and the existing monitoring service can evaluate and deliver both resolver-failure and missing-telemetry alerts.

## Phase 5: User Story 2 - Keep resolver packages current (Priority: P2)

**Goal**: Ensure Unbound's latest-available package task uses fresh package metadata and make package currency verifiable.

**Independent Test**: After the normal update process, compare the installed Unbound version with the latest version from each node's configured supported repositories; if repository access fails, report currency as unverified.

### Implementation

- [X] T006 [US2] Update the Unbound apt task in `roles/unbound/tasks/main.yml` to retain `state: latest` and refresh package metadata when it is older than 3600 seconds using `update_cache: yes` and `cache_valid_time: 3600`.

**Checkpoint**: A normal Ansible run can install the latest Unbound package available from current repository metadata.

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Keep the validation guide aligned with the final rule and package behavior.

- [X] T007 Update `specs/003-unbound-dns-monitoring/quickstart.md` with the confirmed Prometheus target labels, rule-import path, selected SERVFAIL threshold, and a package-version check using configured repository metadata.

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No work; the Ansible project is already initialized.
- **Foundational (Phase 2)**: No new blocking work; the existing Unbound and exporter roles are available.
- **User stories**: US1 and US3 can be developed independently. US2 modifies the same role task file as US1 and should follow T002. Phase ordering follows the P1 stories before P2.
- **Polish (Phase 6)**: T007 follows T004 and T006 so the quickstart can state the final rule and package behavior.

### User Story Dependencies

- **US1 (P1)**: Independent; T002 depends on T001 because it installs the new template.
- **US3 (P1)**: Independent of resolver policy changes because aggregate Unbound statistics and exporter availability are already configured; T004 depends on T003, and T005 depends on T004.
- **US2 (P2)**: T006 follows T002 because both update `roles/unbound/tasks/main.yml`.

### Requirement Mapping

- **US1** covers FR-001–FR-005 and SC-001–SC-003.
- **US2** covers FR-006 and the package-currency portion of SC-001.
- **US3** covers FR-007–FR-012 and SC-004–SC-007.
- **FR-013** is covered by the Ansible-managed resolver policy (T001–T002) and repository-managed alert rules (T003–T005).

### Parallel Opportunities

- T001 and T003 can run in parallel because they edit separate files and have no dependency on each other.
- After T002 and T003 complete, T004 and T006 can run in parallel because they edit separate files.
- T007 is sequential after T004 and T006.

## Parallel Example

```text
# Start the resolver template and external monitoring contract discovery together:
T001: Create roles/unbound/templates/resolver-policy.conf
T003: Confirm Prometheus labels/import path in specs/003-unbound-dns-monitoring/contracts/prometheus-alerting.md

# Once the resolver role wiring and contract discovery are complete:
T004: Add monitoring/prometheus/tor-exit-dns.rules.yml
T006: Refresh Unbound apt metadata in roles/unbound/tasks/main.yml
```

## Implementation Strategy

1. Deliver US1 as the security MVP: explicit loopback-only resolver access and protective settings.
2. Deliver US3 before declaring issue #11 acceptance met; alerting is also a P1 outcome and depends on confirming the external rule-import details.
3. Complete US2 package metadata freshness as the P2 increment.
4. Finish T007 so the quickstart reflects the final package and monitoring configuration.

Separate automated test tasks are not included because the feature request did not ask for tests. Use the independent acceptance checks above and the scenarios in `quickstart.md` during implementation review.

## Phase 7: Convergence

- [ ] T008 Have the monitoring owner confirm the external Prometheus target labels, rule-import path, and notification route; update `specs/003-unbound-dns-monitoring/contracts/prometheus-alerting.md` and `ANSIBLE_RUNBOOK.md` with the confirmed integration inputs per FR-010 (partial).
- [ ] T009 Review observed `unbound_answer_rcodes_total{rcode="SERVFAIL"}` data, replace the provisional threshold in `monitoring/prometheus/tor-exit-dns.rules.yml`, and validate firing/recovery behavior with the external Prometheus rule checker per FR-008 and SC-004 (partial).
- [ ] T010 Update `monitoring/prometheus/tor-exit-dns.rules.yml` and `specs/003-unbound-dns-monitoring/contracts/prometheus-alerting.md` to cover every active Tor exit target using the confirmed labels and detect missing telemetry per expected node per FR-007 and FR-011 (partial).
- [ ] T011 Run the resolver, package, and alert acceptance checks against the targeted nodes and existing monitoring service, then record results and any unverified conditions in `specs/003-unbound-dns-monitoring/quickstart.md` per SC-001–SC-006 (partial).
