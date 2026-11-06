# Tasks: One Tor Relay Family

**Input**: Design documents from `specs/005-tor-family-id/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [operator-inputs.md](contracts/operator-inputs.md), [quickstart.md](quickstart.md)

**Tests**: No automated test suite was requested. The independent checks below use the validation scenarios in `specs/005-tor-family-id/quickstart.md`.

**Organization**: Tasks are grouped by the three user stories in `spec.md`. All family keys and IDs refer to one operator family for every active relay.

## Format: `[ID] [P?] [Story] Description`

- **[P]** means different files can be worked on in parallel after their stated prerequisites.
- **[US1]**, **[US2]**, and **[US3]** map to the prioritized stories in `spec.md`.
- Paths are relative to the repository root.

## Phase 1: Setup

**Purpose**: Establish the non-secret family metadata paired with the operator's existing Tor-generated binary key.

- [ ] T001 Record the public FamilyID from the key's companion `.public_family_id` and the secret file's SHA-256 digest in `group_vars/all/tor`; require one present Tor-syntax public ID and a 64-character hexadecimal digest, and keep the binary key outside Git.

**Checkpoint**: One public ID and pinned digest represent the single operator family; no secret bytes are committed.

---

## Phase 2: Foundational Preflight

**Purpose**: Reject invalid controller input before any targeted relay's family configuration changes.

**⚠️ CRITICAL**: This phase blocks all user stories.

- [X] T002 Add a first, localhost-only preflight play in `playbook.yml`, tagged `tor`, that requires a nonempty active `all-servers` group and a set, absolute, readable `TOR_FAMILY_KEY_FILE` path; run it for both full playbooks and `--tags tor` without printing key bytes.
- [X] T003 Complete the `playbook.yml` preflight by comparing the local key's SHA-256 with `group_vars/all/tor`, rejecting missing or mismatched public metadata, and suppressing secret-bearing task output and diffs before any relay family change.

**Checkpoint**: A missing, unreadable, relative, or substituted local file stops the playbook on the controller, including when the active inventory is empty.

---

## Phase 3: User Story 1 - Publish one operator family (Priority: P1) 🎯 MVP

**Goal**: All three current relays publish the same supported family identity, with no managed `MyFamily` list.

**Independent Test**: Render and validate both relay types, then check each current fingerprint in fresh public Tor data for a family certificate and the same `ed25519:` family ID after an authorized compatible deployment.

### Implementation

- [X] T004 [US1] Add a target capability check after Tor package installation in `roles/tor/tasks/main.yml` that requires Tor to advertise the `FamilyId` option before any family key or `torrc` family change on that target.
- [X] T005 [US1] Add a shared `tor@default` restart handler in `roles/tor/handlers/main.yml` for family key changes, preserving the existing relay and exit template restart behavior.
- [X] T006 [US1] Install the controller key byte-for-byte as a single `.secret_family_key` file in `/var/lib/tor/keys` from `roles/tor/tasks/main.yml` before template roles run; set `debian-tor:debian-tor`, mode `0600`, `no_log`, `diff: false`, and notify the shared handler on change.
- [X] T007 [P] [US1] Replace the fingerprint-derived `MyFamily` line with the explicit shared `FamilyId` in `roles/tor-relay/templates/torrc`; render exactly one public ID and no reference to other relay fingerprints.
- [X] T008 [P] [US1] Replace the fingerprint-derived `MyFamily` line with the same explicit shared `FamilyId` in `roles/tor-exit/templates/torrc`; render exactly one public ID and no reference to other relay fingerprints.
- [X] T009 [US1] Validate `playbook.yml`, `roles/tor/tasks/main.yml`, and both `torrc` templates with syntax and non-production rendering checks from `specs/005-tor-family-id/quickstart.md`; confirm both templates use the same public ID and no `MyFamily`.
- [ ] T010 [US1] After a separately authorized rollout on a compatible host baseline, use `specs/005-tor-family-id/quickstart.md` to check tor01, tor02, and tor03 by exact fingerprint and fresh `last_seen`; require each public record's `family_cert` and expected `family_ids`, and record pending or failed members without key output.

**Checkpoint**: Current active relays are verified as one family; if deployment is unavailable, retain T010 as pending rather than claiming publication.

---

## Phase 4: User Story 2 - Add or retire a relay (Priority: P2)

**Goal**: A future active relay joins the same family without changes to existing members' family settings, and a retired relay is absent from active configuration.

**Independent Test**: Use a temporary inventory copy with a prospective active relay and then a retired relay; inspect target selection and rendered family settings without changing production inventory.

### Implementation

- [X] T011 [P] [US2] Add the temporary-inventory membership validation scenario to `specs/005-tor-family-id/quickstart.md`; show that the active `tor-relay` and `tor-exit` union uses the same shared public ID and no per-relay fingerprint list.
- [X] T012 [P] [US2] Document adding and retiring an active relay in `ANSIBLE_RUNBOOK.md`, including use of the same operator key and public ID, target selection from `inventory`, and public membership verification; do not add recovery or rotation steps.

**Checkpoint**: Prospective members inherit the family, retired hosts are excluded, and existing family configuration needs no edits.

---

## Phase 5: User Story 3 - Deploy with a local key (Priority: P3)

**Goal**: Routine deployment reads the persistent local key without unlocking the password manager.

**Independent Test**: Run the wrapper with a valid external key path, then run non-production missing and wrong-file cases; the valid case reaches Ansible preflight, while invalid cases stop without exposing key bytes or changing relay family settings.

### Implementation

- [X] T013 [US3] Update `run_ansible.sh` to validate and mount `TOR_FAMILY_KEY_FILE` read-only into Docker when set, pass only its in-container path to Ansible, and fail clearly on an unreadable path without echoing secret bytes; preserve forwarded arguments and allow unrelated non-Tor playbooks without the key.
- [X] T014 [US3] Document the local binary key path, optional external `.env` path assignment, and native versus Docker invocation in `ANSIBLE_RUNBOOK.md`; explicitly keep key bytes out of `.env`, Git, task output, and diffs.
- [X] T015 [US3] Validate the valid, missing, and wrong-key controller cases using `specs/005-tor-family-id/quickstart.md` and `run_ansible.sh`; require no password-manager access for the valid case and no relay family change or secret output for invalid cases.

**Checkpoint**: The existing wrapper supports the approved local-key workflow and fails before relay changes on bad input.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Confirm the combined change remains narrow and reviewable.

- [X] T016 Re-run the full syntax, inventory, rendered-configuration, and secret-output checks in `specs/005-tor-family-id/quickstart.md` against `playbook.yml`, `roles/tor/tasks/main.yml`, `roles/tor-relay/templates/torrc`, `roles/tor-exit/templates/torrc`, and `run_ansible.sh`; confirm no generated key or `MyFamily` remains in managed files.
- [X] T017 Review `ANSIBLE_RUNBOOK.md` and `specs/005-tor-family-id/quickstart.md` against `specs/005-tor-family-id/spec.md`; keep unsupported-host deployment and unobserved publication explicitly pending, and exclude recovery and rotation procedures.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational preflight (Phase 2)** → **US1 (Phase 3)**.
- **US2 (Phase 4)** and **US3 (Phase 5)** depend on the shared foundation and use US1's family behavior for their independent checks.
- **Polish (Phase 6)** follows the implementation of all desired stories. T010's live-publication acceptance remains pending until a compatible baseline and separately authorized deployment exist.

### User Story Dependencies

- **US1**: Implements the shared Tor behavior after T001–T003. T004 precedes T006; T005 provides T006's handler; T007 and T008 can proceed in parallel after the public ID is defined.
- **US2**: Documents and validates future inventory changes using US1's shared family behavior. T011 and T012 touch different files and can proceed in parallel.
- **US3**: Extends the controller interface around the foundational preflight. T013 precedes T015; T014 can start once the wrapper input contract is settled.

### Parallel Opportunities

- **US1**: T007 and T008 change separate relay and exit templates after T001.
- **US2**: T011 and T012 change separate validation and runbook files.
- **Across stories**: T013 in `run_ansible.sh` can proceed while T007–T008 update templates, after the input contract is fixed. Coordinate T012 and T014 because both edit `ANSIBLE_RUNBOOK.md`.

## Parallel Examples

- **US1**: Implement T007 in `roles/tor-relay/templates/torrc` and T008 in `roles/tor-exit/templates/torrc` at the same time.
- **US2**: Implement T011 in `specs/005-tor-family-id/quickstart.md` and T012 in `ANSIBLE_RUNBOOK.md` at the same time.
- **US3**: Implement T013 in `run_ansible.sh` while US1 template work is underway; sequence T014 after T012 if both stories are active.

## Implementation Strategy

### MVP First

1. Complete T001–T003 so the operator-supplied key is checked before any relay family change.
2. Complete T004–T009 to install the key and configure both relay types.
3. On a supported and compatible node baseline, seek rollout authorization and complete T010 to prove network-visible membership. Until then, the MVP is implemented but publication remains unverified.

### Incremental Delivery

1. Add US2 documentation and temporary-inventory validation without editing existing members' family settings.
2. Add US3 wrapper support for routine deployments from the local binary key.
3. Complete T016–T017 for combined validation and review. No recovery or rotation work is in scope.
