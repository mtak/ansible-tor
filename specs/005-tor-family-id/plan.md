# Implementation Plan: One Tor Relay Family

**Branch**: `005-tor-family-id` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-tor-family-id/spec.md`

## Summary

Configure every active managed Tor relay as a member of one FamilyID family. Keep the binary family secret outside Git on the controller, make it available to both native Ansible and the repository's Docker wrapper, and pin its expected SHA-256 digest and public FamilyID in shared variables. Preflight the input before changes, copy the secret to each relay before writing `torrc`, remove `MyFamily` from both templates, and verify published family certificates and client-visible family IDs. Current membership is tor01, tor02, and tor03; future active relays inherit the same family without listing fingerprints.

## Technical Context

**Language/Version**: YAML/Jinja2 with ansible-core 2.21.4 on the observed controller; Tor 0.4.9.16 on all three observed relays. The managed OS and remote Python must meet the existing runbook and constitution prerequisites before live deployment.

**Primary Dependencies**: Ansible built-in modules and lookups, Tor Project packages, optional `run_ansible.sh` Docker wrapper, `sha256sum` or Ansible checksum support, Tor Metrics Onionoo for external publication checks.

**Storage**: One Tor-generated binary family key in a persistent controller file outside Git and copied to each relay's Tor key directory; public FamilyID and expected key digest in shared managed variables. The operator stores the key's base64 encoding in a password manager and keeps the decoded binary file on the controller.

**Testing**: Static syntax and inventory checks; controller input preflight including checksum; non-production missing/wrong-key checks; Tor option and configuration validation; live published `family_cert` and `family_ids` checks after an approved deployment.

**Target Platform**: Supported Debian or Ubuntu LTS relay hosts managed through the existing Ansible inventory. Current hosts report Debian 10 and Python 3.7.3 in the 2026-10-23 baseline, so a supported OS/Python controller path is a prerequisite for applying this plan with current ansible-core.

**Project Type**: Infrastructure configuration repository.

**Performance Goals**: No runtime throughput change; a new active relay joins the family without edits to existing members' family configuration.

**Constraints**: Secret bytes never enter Git, Ansible logs, diffs, or public `torrc`; failure on missing or mismatched controller key before relay family changes; all active relays share one explicit FamilyID; no recovery or rotation procedure in this feature.

**Scale/Scope**: Three active relays today across `tor-relay` and `tor-exit`, plus future relays added to those active inventory groups. No changes to relay identity keys, exit policy, or unrelated services.

## Constitution Check

*GATE: Passed before Phase 0 research; rechecked after Phase 1 design.*

| Principle | Assessment |
| --- | --- |
| Preserve service boundaries | PASS. Shared Tor key installation belongs in `roles/tor`; relay-specific `torrc` remains in `roles/tor-relay` and `roles/tor-exit`. The controller wrapper only exposes the operator's local key to Ansible. |
| Reproducible and replaceable nodes | PASS. A new node receives the same family configuration from inventory, public variables, and the operator-supplied local key. The key remains available to the operator without being committed. |
| Tor Project guidance | PASS. Use the Tor-supported FamilyID key and certificate mechanism; remove the obsolete MyFamily lines after verifying current network behavior. |
| Minimize stored user information | PASS. Checks use relay identities and public descriptor metadata only; no Tor-user data is collected. |
| Understandable operational change | PASS. Changes are limited to shared Tor configuration, two torrc templates, the controller wrapper, and the runbook. No new service or background component. |
| Operational policies | PASS with deployment prerequisite. No package pinning or identity-key backup changes. Live deployment waits for supported Debian/Ubuntu LTS and a compatible remote Python/controller combination as already required by the runbook. |

The constitution permits applying the change to all targeted nodes together. No exception or complexity waiver is needed.

## Project Structure

### Documentation (this feature)

```text
specs/005-tor-family-id/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── operator-inputs.md
└── tasks.md                 # Created by $speckit-tasks, not this phase
```

### Source Code (repository root)

```text
inventory
group_vars/all/tor              # Public FamilyID and expected secret digest
playbook.yml                    # Controller preflight before Tor family changes
roles/tor/tasks/main.yml        # Shared key install and Tor capability check
roles/tor-relay/templates/torrc # FamilyID for non-exit relays
roles/tor-exit/templates/torrc  # FamilyID for exit relays
run_ansible.sh                  # Read-only mount of external key for Docker runs
ANSIBLE_RUNBOOK.md              # Local input, membership, and publication checks
```

**Structure Decision**: Use the current shared Tor role and existing relay/exit template boundaries. The preflight runs before managed family changes; the Docker wrapper is updated because its current mounts cannot see a controller key outside the repository. The public ID and digest live with shared Tor variables so all active members use the same values. No new role, daemon, or bespoke key parser is needed.

## Phase 0: Research Decisions

See [research.md](research.md). Tor 0.4.9.16 supports `FamilyId`; consensus method 38 uses `family-ids` instead of legacy family lines. Tor's configuration verification alone cannot validate the secret/ID pair, so the plan pins a digest from the Tor-generated key and checks publication after application. The Docker wrapper needs an explicit read-only file mount.

## Phase 1: Design and Contracts

See [data-model.md](data-model.md), [operator-inputs.md](contracts/operator-inputs.md), and [quickstart.md](quickstart.md). Controller input checks run before target changes. The shared Tor role installs the key with service-account ownership and restricted permissions; both `torrc` templates use the same explicit public ID. Publication checks must identify each relay by fingerprint and fresh observation time, require `family_cert`, and require the expected `family_ids` entry. An offline or unobserved relay remains pending rather than counted as verified.

## Post-Design Constitution Recheck

PASS. The chosen artifacts preserve role boundaries, keep managed state reproducible from operator-supplied secret material and repository configuration, follow current Tor guidance, and use only public relay metadata for verification. The wrapper change is necessary to support the approved local-key workflow. No constitution violations remain.
