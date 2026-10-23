# Implementation Plan: Rebuild TakTor Nodes on Ubuntu 26.04 LTS

**Branch**: `001-ubuntu-node-rebuild` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)

**Input**: [Feature specification](spec.md)

## Summary

Reprovision the three active Tor nodes (`tor01`, `tor02`, `tor03`) on Ubuntu 26.04 LTS and restore their existing Ansible-managed services and routine Tor identities. CloudServer's 24.04 image is the starting image; release-upgrade each node before Ansible configures it. Keep the current role boundaries. Derive the Tor Project apt suite from the target distribution codename, scope the signing key to that source, and manage the actual `tor@default` service. Before any provider rebuild, verify a decryptable encrypted backup of the complete Tor keys directory and match the restored fingerprint to inventory. See [research.md](research.md) for source findings and decisions.

## Technical Context

**Language/Version**: Ansible YAML; controller baseline is ansible-core 2.21.4 with Python 3.14.4.

**Primary Dependencies**: Ansible built-in apt/systemd/file/template modules; Ubuntu 26.04 LTS (Resolute) packages; Tor Project Debian/Ubuntu package repository; age-encrypted backup submodule.

**Storage**: Git-managed inventory, group/host variables, playbooks and role files; encrypted Tor identity backups in `ansible-tor-backup` submodule; Tor data on managed nodes under `/var/lib/tor`.

**Testing**: No repository CI or automated test suite was found. Validate with Ansible syntax and connectivity checks, configured service state, role-specific Tor policy, Tor external reachability, and identity fingerprint checks. Do not treat SSH/raw success as proof that Ansible modules work.

**Target Platform**: Three CloudServer VMs using Ubuntu 26.04 LTS (Resolute), x86_64/amd64; provider image starts at Ubuntu 24.04 LTS and is release-upgraded before configuration.

**Project Type**: Ansible infrastructure/configuration repository.

**Performance Goals**: No new performance target. Preserve configured bandwidth limits and existing monitoring behavior.

**Constraints**: The provider rebuild erases VM data. Verify identity recovery material before erasure; do not restore a compromised identity. Keep the existing role ownership. Use latest available packages. Make the outage explicit. The constitution permits all targeted nodes to be handled in one rollout.

**Scale/Scope**: Three active nodes: two non-exit relays and one exit relay. No application service or external API is introduced.

## Constitution Check

- **Service boundaries**: PASS. Shared host configuration and per-service responsibilities remain in existing roles. The Tor apt source and daemon setup remain in `roles/tor`; relay and exit configuration remain in their existing roles; encrypted identity backup handling remains in the backup playbook/repository.
- **Reproducibility and replaceability**: PASS. Inventory and Ansible roles remain the source of managed configuration; provider rebuild is a one-time external prerequisite.
- **Tor Project guidance**: PASS WITH DESIGN ACTION. Use the Tor Project repository with the Ubuntu distribution codename and a scoped signing key; manage the installed `tor@default` service and validate external reachability. Back up the complete Tor keys directory securely.
- **Aggregate-only monitoring**: PASS. Existing exporters and report behavior are retained; no user-specific metrics are added.
- **Understandable operational changes**: PASS. Changes stay within the existing playbook and role structure.
- **Operating system and package policy**: PASS. Ubuntu 26.04 LTS is allowed by the amended constitution; Ansible-managed packages remain at latest available versions.
- **Identity policy**: PASS WITH PRECONDITION. Routine recovery preserves keys; suspected compromise uses new keys. A complete, decryptable backup with matching fingerprint is a hard gate before any disk erasure.
- **Rollout shape**: PASS. The constitution allows a single rollout across all targeted nodes; the plan makes the outage and preflight gates explicit.

## Project Structure

### Documentation (this feature)

```text
specs/001-ubuntu-node-rebuild/
├── plan.md              # This file
├── research.md          # Compatibility, repository, and recovery decisions
├── data-model.md        # Node, identity backup, and service-role records
├── quickstart.md        # Preflight and end-to-end validation guide
├── contracts/           # Not needed: internal Ansible configuration, no public API
└── tasks.md             # Created later by $speckit-tasks
```

### Source Code (repository root)

```text
inventory
host_vars/                  # Per-node role, address-related, and fingerprint values
group_vars/                 # Shared Ansible variables
playbook.yml                # Main configuration entry point
backup.yml                  # Encrypted Tor identity backup workflow
roles/
├── base/                   # Shared OS configuration and packages
├── ssh/
├── iptables/
├── haveged/
├── unbound/
├── tor/                    # Tor repository, package, and base daemon setup
├── tor-relay/              # Relay-only Tor policy
├── tor-exit/               # Exit-only Tor policy
├── prometheus-exporters/
└── report/
ansible-tor-backup/         # Encrypted identity backup submodule
```

**Structure Decision**: Update existing Ansible inventory/host variables, `backup.yml`, and the existing service roles only where Ubuntu compatibility requires it. No new application, API, or test project is introduced. If provider metadata is maintained in host variables, reconcile the existing `CloudVPS.com` values with the operator-identified CloudServer provider; current playbook tasks do not consume that field.

## Complexity Tracking

No constitution violations or additional architectural components are proposed.
