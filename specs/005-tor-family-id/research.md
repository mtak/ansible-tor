# Research: Tor Relay FamilyID

**Date**: 2026-11-06

## 1. Family mechanism

- **Decision**: Use one explicit `FamilyId` on every active relay, backed by the same Tor-generated `.secret_family_key` file. Remove `MyFamily` from both managed templates.
- **Rationale**: The three live relays reported Tor 0.4.9.16, which accepts `FamilyId`. Their cached consensus reported method 38. Consensus methods 37 and later omit legacy family lists in microdescriptors and use family IDs; `MyFamily` alone cannot provide the intended client-visible relationship. Tor's current post-install guide says MyFamily has been removed, though the installed Tor parser still accepts it.
- **Alternatives considered**: Keep only `MyFamily` (insufficient); configure both (retains obsolete inventory-derived lists); use `FamilyId *` (could include unintended keys).
- **Sources**: [Tor family setup](https://community.torproject.org/relay/setup/post-install/family-ids/), [Tor relay post-install guidance](https://community.torproject.org/relay/setup/post-install/), [Tor microdescriptor specification](https://spec.torproject.org/dir-spec/computing-microdescriptors.html), live read-only observations on tor01–tor03 on 2026-11-06.

## 2. Key format and storage

- **Decision**: Treat the Tor-generated family secret as a binary file. The operator retains it in a password manager and keeps a byte-for-byte local file outside Git for routine deployments. Copy it into each relay's key directory under a name ending `.secret_family_key`, owned by the Tor service account with restricted permissions. Store the generated public FamilyID as non-secret shared configuration.
- **Rationale**: `tor --keygen-family <basename>` produces the secret file and companion public identifier. Tor uses the secret to sign family certificates. A raw secret in `.env`, a template, or inventory risks corrupting binary bytes or revealing them. The live default `/var/lib/tor/keys` is owned by `debian-tor` with restricted directory permissions.
- **Alternatives considered**: Put secret bytes in `.env` (binary and disclosure problems); require unlocking an encrypted vault on each run (operator declined); manually copy keys to relays (breaks reproducibility).
- **Sources**: [Tor family setup](https://community.torproject.org/relay/setup/post-install/family-ids/), [Tor 0.4.9.16 source](https://dist.torproject.org/tor-0.4.9.16.tar.gz), read-only live directory metadata.

## 3. Preflight and validation

- **Decision**: Pin the expected SHA-256 digest of the initial secret alongside the public FamilyID. Before relay family changes, check that the operator's absolute local path exists, is readable, and hashes to that digest; check target Tor capability. Validate rendered `torrc` syntax separately. Require published network evidence before marking the migration complete.
- **Rationale**: The digest rejects a missing or substituted local key without exposing its bytes. It is recorded from the same generated key pair as the public FamilyID. Tor `--verify-config` checks syntax but does not load or compare the family key. Tor checks key/ID matching during startup or reload; a reload failure can retain old keys. Syntax check or restart alone does not prove publication.
- **Alternatives considered**: Rely on `--verify-config` alone (does not validate the key); parse Tor's secret format in new code (unnecessary complexity); rely on file name or size (insufficient).
- **Sources**: [Tor 0.4.9.16 source](https://dist.torproject.org/tor-0.4.9.16.tar.gz), especially `src/app/main/main.c`, `src/feature/relay/router.c`, and `src/feature/relay/routerkeys.c`; [Tor manual](https://manpages.debian.org/testing/tor/tor.1.en.html).

## 4. Ansible and controller integration

- **Decision**: Use the existing shared Tor role to install the key after Tor is available and before relay/exit `torrc` changes. Keep the public FamilyID in shared variables and the `FamilyId` line in both templates. Update `run_ansible.sh` to make the external key available inside Docker as a read-only file. Suppress sensitive task output and diffs.
- **Rationale**: The playbook applies `roles/tor` to all active nodes before the two `torrc` roles. The wrapper currently mounts only the repo, SSH directory, and agent socket. `ansible.cfg` enables argument display, making output suppression important.
- **Alternatives considered**: Duplicate key-copy tasks (drift risk); move the key into the repo (violates approved storage); require native Ansible only (strands wrapper workflow).
- **Sources**: `playbook.yml`, Tor role/task files, `run_ansible.sh`, `ansible.cfg`; [Ansible copy module](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/copy_module.html).

## 5. Publication and platform prerequisite

- **Decision**: Check each active fingerprint in fresh public Tor data for a family certificate and the same expected `ed25519:` family ID. Report verified, pending, or failed. Require the existing supported OS and compatible remote Python prerequisite before live rollout.
- **Rationale**: Onionoo exposes `family_cert`, `family_ids`, `fingerprint`, and `last_seen`. A missing or stale record cannot prove publication. The runbook records Debian 10/Python 3.7.3 and an ansible-core 2.21.4 module compatibility failure, so live deployment awaits a compatible baseline outside this feature.
- **Alternatives considered**: Treat `torrc` or restart as proof (not network-visible); use only local Tor control data (does not prove authority publication); bundle OS migration (unrelated scope).
- **Sources**: [Onionoo protocol](https://metrics.torproject.org/onionoo.html), [Tor control protocol](https://spec.torproject.org/control-spec/commands.html), `ANSIBLE_RUNBOOK.md`, [project constitution](../../.specify/memory/constitution.md).

## Open Clarifications

None for planning. The operator supplies the original key from the password manager and a persistent local copy before deployment. This feature does not define or test recovery or rotation procedures.
