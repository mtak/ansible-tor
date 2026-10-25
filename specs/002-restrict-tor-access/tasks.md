# Tasks: Restrict Tor Control and Metrics Access

**Input**: Design documents from `specs/002-restrict-tor-access/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`

**Tests**: No automated test files are requested. Manual acceptance checks are included because the specification requires confirming access denial and continued monitoring. The operator will validate Nyx separately.

**Organization**: Tasks are grouped by the three user stories in `spec.md`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Tasks that can run in parallel because they edit separate files and have no unfinished dependencies.
- **[Story]**: The user story served by the task.
- Paths are repository-relative.

## Phase 1: Setup

**Purpose**: Confirm the existing Ansible project structure.

No initialization tasks are needed; the repository already contains the Ansible roles, inventory, and group variables identified in `plan.md`.

---

## Phase 2: Foundational

**Purpose**: Shared blocking infrastructure for user stories.

No shared foundational changes are required. User Story 1 can proceed independently, and User Story 2 uses the source allowlist already applied by the firewall.

---

## Phase 3: User Story 1 - Protect Tor Control Access (Priority: P1) 🎯 MVP

**Goal**: Limit Tor control to local authenticated clients while preserving the exporter and Nyx functions.

**Independent Test**: After applying the Tor configuration, remote control attempts and unauthenticated control requests are denied, and the `debian-tor` exporter can authenticate locally and perform its required operations. The operator will validate Nyx separately.

### Implementation and Acceptance Checks for User Story 1

- [ ] T001 [US1] Set the control listener to loopback and enable cookie authentication in `roles/tor-relay/templates/torrc` and `roles/tor-exit/templates/torrc`.
- [ ] T002 [US1] Verify a remote connection to ControlPort is denied, an unauthenticated local control command is rejected, and the exporter running as `debian-tor` negotiates SAFECOOKIE; follow `specs/002-restrict-tor-access/quickstart.md` and review `roles/prometheus-exporters/templates/prometheus-tor-exporter` for its local connection settings.

**Checkpoint**: The exporter retains authenticated local control access, remote and unauthenticated control access is denied, and the operator validates Nyx separately.

---

## Phase 4: User Story 2 - Preserve Authorized Metrics Scraping (Priority: P1)

**Goal**: Restrict Tor's native MetricsPort to the existing authorized `control_ip` sources while preserving authorized scrapes.

**Independent Test**: Requests to port 9098 from each configured scraper source return Tor metrics; requests from outside the allowlist are denied. The separate exporter endpoint on port 9099 continues responding to its authorized scraper.

### Implementation and Acceptance Checks for User Story 2

- [ ] T003 [P] [US2] Bind native MetricsPort to the node address(es) reached by Prometheus and replace `MetricsPortPolicy accept *` with the existing `control_ip` source policy, covering both `control_ipv4` and `control_ipv6` sources used by the firewall, in `roles/tor-relay/templates/torrc`.
- [ ] T004 [P] [US2] Apply the same MetricsPort binding and `control_ip` source policy for both address families as the relay in `roles/tor-exit/templates/torrc`.
- [ ] T005 [US2] Verify port 9098 accepts a request from a source in `control_ip` and denies a source outside it; confirm the existing exporter endpoint on port 9099 remains unchanged using `specs/002-restrict-tor-access/quickstart.md`.

**Checkpoint**: Confirmed scraper sources can retrieve metrics; other sources cannot; both Tor node roles behave consistently.

---

## Phase 5: User Story 3 - Understand the Effective Policy (Priority: P2)

**Goal**: Document the effective local control and metrics access policy, including the exact scraper sources.

**Independent Test**: A maintainer can identify authorized control clients, authentication expectations, the metrics port, and authorized scraper addresses from the runbook.

### Implementation for User Story 3

- [ ] T006 [US3] Document the local control boundary, exporter SAFECOOKIE authentication, native metrics listener, and unchanged exporter HTTP endpoint in `ANSIBLE_RUNBOOK.md`; list the effective IPv4 and IPv6 source addresses from the `control_ipv4` and `control_ipv6` variable values in `group_vars/all/external`, and align `specs/002-restrict-tor-access/quickstart.md` with this policy.

**Checkpoint**: The runbook and quickstart describe the same policy that is enforced by Tor and the firewall.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Check consistency across roles, address families, and acceptance outcomes.

- [ ] T007 Review the rendered relay and exit Tor configurations and existing IPv4/IPv6 firewall rules against `group_vars/all/external`, `ANSIBLE_RUNBOOK.md`, and `specs/002-restrict-tor-access/quickstart.md`; confirm ControlPort is local/authenticated, MetricsPort uses `control_ip`, and port 9099 policy is unchanged.
- [ ] T008 Run `ansible-playbook --syntax-check -i inventory playbook.yml` and complete the service restart, exporter, authorized metrics, and unauthorized-source checks in `specs/002-restrict-tor-access/quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No changes required; the existing project structure is already in place.
- **Foundational (Phase 2)**: No shared work required.
- **User Story 1 (Phase 3)**: Can start immediately.
- **User Story 2 (Phase 4)**: T003-T004 use the existing source list and follow T001 because they edit the same Tor configuration files; T005 follows those changes.
- **User Story 3 (Phase 5)**: T006 follows the final access policy decisions from User Stories 1 and 2.
- **Polish (Phase 6)**: T007 and T008 follow implementation and documentation work.

### User Story Dependencies

- **User Story 1 (P1)**: Independent; it does not depend on the metrics allowlist.
- **User Story 2 (P1)**: Its acceptance outcome is independent and it reuses the existing firewall source allowlist, but its Tor template edits follow T001 because both stories change the same files.
- **User Story 3 (P2)**: Depends on both access policies being established so the documentation can state exact behavior and addresses.

### Parallel Opportunities

- T003 and T004 can proceed in parallel after T001 because they modify separate Tor role templates.

## Parallel Example: User Story 2

```text
Task: T003 update roles/tor-relay/templates/torrc
Task: T004 update roles/tor-exit/templates/torrc
```

## Implementation Strategy

### MVP First (User Story 1)

Complete T001-T002 to secure remote control access while preserving local Nyx and exporter functions. This is an independently verifiable increment; it does not complete issue #5 until User Story 2 also restricts native metrics access.

### Incremental Delivery

1. Complete User Story 1 and verify local authenticated access.
2. Complete User Story 2 using `control_ip` and verify port 9098 allow/deny behavior.
3. Complete User Story 3 and cross-cutting validation so the documented policy matches both Tor and firewall enforcement.

## Notes

- Task IDs are sequential and all tasks include a story label where required, plus a repository file path.
- `[P]` marks only tasks that can proceed independently after their stated prerequisites.
- Manual service and network checks are required by the feature acceptance criteria; no automated tests are added.
- The operator will verify Nyx access separately; the task checklist does not prescribe Nyx checks.
