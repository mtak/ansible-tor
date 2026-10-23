---
description: "Task list for Ubuntu 26.04 compatibility in the Tor node Ansible repository"
---

# Tasks: Rebuild TakTor Nodes on Ubuntu 26.04 LTS

**Input**: Design documents from `/specs/001-ubuntu-node-rebuild/`

**Prerequisites**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md)

**Tests**: No test tasks were requested. Use the documented Ansible syntax/connectivity and operational checks when applying to the upgraded hosts.

**Organization**: Tasks are grouped by user story to retain traceability to the approved specification.

## Phase 1: Setup

**Purpose**: No new project structure or dependencies are required for this Ansible-only change.

## Phase 2: Foundational

**Purpose**: No shared infrastructure changes are needed before the story-specific Ansible updates.

## Phase 3: User Story 1 - Rebuild and Manage the Active Nodes (Priority: P1) 🎯 MVP

**Goal**: Make the existing Tor package configuration compatible with the final Ubuntu 26.04 (Resolute) OS and supported Ansible controller.

**Independent Test**: On a rebuilt and upgraded tor01, Ansible module connectivity succeeds, the Tor package source resolves to `resolute`, and Tor packages install from the Tor Project repository.

### Implementation for User Story 1

- [x] T001 [US1] Replace the global `apt_key` and hard-coded Buster source with a repository-scoped Tor signing key and distribution-codename source in `roles/tor/tasks/main.yml` and `roles/tor/templates/tor.sources`.
- [x] T002 [US1] Change the package-update task description from Debian-only to all managed nodes in `update.yml`.

## Phase 4: User Story 2 - Preserve Relay Identity During Routine Rebuild (Priority: P1)

**Goal**: Preserve routine identity recovery requirements while changing the host OS.

**Independent Test**: Restoring the existing Tor keys on the upgraded OS yields the recorded per-host fingerprint; compromised nodes do not restore old keys.

### Implementation for User Story 2

- No OS-specific Ansible changes are required for the existing identity recovery policy. Keep the key backup and recovery gates defined in `spec.md`; do not change key material as part of the package/service compatibility tasks.

## Phase 5: User Story 3 - Retain Existing Relay and Host Services (Priority: P2)

**Goal**: Ensure relay and exit roles manage the Tor daemon instance provided by Ubuntu rather than the multi-instance wrapper unit.

**Independent Test**: Applying relay or exit configuration enables and starts `tor@default`; handler notifications restart that same daemon instance.

### Implementation for User Story 3

- [x] T003 [US3] Update the relay and exit service tasks and restart handlers to manage `tor@default` in `roles/tor-relay/tasks/main.yml`, `roles/tor-relay/handlers/main.yml`, `roles/tor-exit/tasks/main.yml`, and `roles/tor-exit/handlers/main.yml`.

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Keep operator guidance aligned with the target OS.

- [x] T004 Update the Ansible runbook with Ubuntu 26.04 target checks and the Tor service unit name in `ANSIBLE_RUNBOOK.md`.
- [x] T005 Review the implementation diff against `spec.md`, `plan.md`, and the current role boundaries.

## Dependencies & Execution Order

### Phase Dependencies

- Setup and Foundational phases require no work.
- User Story 1 Tor repository changes precede applying Tor roles to a new host.
- User Story 3 service-unit changes can be implemented independently of the apt-source changes.
- Polish follows the implementation tasks.

### User Story Dependencies

- **US1 (P1)**: Independent; required before Ansible configures Ubuntu 26.04.
- **US2 (P1)**: Existing backup/recovery policy is unchanged by OS compatibility work.
- **US3 (P2)**: Independent code change; required for reliable Tor service start/restart on Ubuntu.

### Parallel Opportunities

- T001 and T003 touch different role files and can be implemented independently.
- T004 follows both implementation tasks because it documents their final behavior.

## Implementation Strategy

### MVP First

1. Complete T001 and T002 for Ubuntu 26.04 apt compatibility.
2. Complete T003 so Ansible controls the actual Tor daemon instance.
3. Update the runbook and review the final diff.
4. Apply to tor01 first and confirm connectivity, Tor identity, and external reachability before proceeding with the remaining hosts.

### Incremental Delivery

The package-source and service-unit changes are the necessary Ansible compatibility increment. The existing identity backup policy remains a prerequisite for destructive rebuilds and is not altered by this OS-specific change.
