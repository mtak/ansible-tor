# Research: Ubuntu 26.04 Node Rebuild

## Decisions

### Managed-node Python compatibility

- **Decision**: Use Ubuntu 26.04 LTS and verify the detected remote Python interpreter before module-based configuration.
- **Rationale**: The runbook records ansible-core 2.21.4 on Python 3.14.4 and remote Debian 10 hosts on Python 3.7.3; the current ping module fails to parse on those hosts. The Ansible support matrix lists Python 3.9–3.14 for managed nodes under ansible-core 2.21. Ubuntu 26.04 uses Python 3.14; verify the actual interpreter on each upgraded node.
- **Alternatives considered**: Keep Debian 10 and bootstrap a compatible interpreter with `raw`; this retains an end-of-life base and requires a separate bootstrap path. Stay on the provider's Ubuntu 24.04 image; this is supported but gives a shorter support window than 26.04.
- **Sources**: [Ansible Core release and maintenance](https://docs.ansible.com/projects/ansible-core/devel/reference_appendices/release_and_maintenance.html); [Ubuntu 26.04 release notes](https://documentation.ubuntu.com/release-notes/26.04/); repository `ANSIBLE_RUNBOOK.md`.

### Tor package repository and service

- **Decision**: Replace the hard-coded `buster` Tor package suite with the target distribution's codename and use a repository-scoped signing key. Manage the package's `tor@default` systemd instance from relay and exit roles.
- **Rationale**: Tor Project publishes packages for current Ubuntu releases through their LTS support cycles and documents a `Signed-By` keyring. Its `resolute` repository suite is published. `roles/tor/tasks/main.yml` currently uses `buster`, legacy `apt_key`, and a global apt repository. Relay and exit roles currently name the `tor` wrapper service instead of the actual daemon instance.
- **Alternatives considered**: Ubuntu Universe Tor packages are not selected because Tor Project advises using its repository for current updates. Keeping the Buster suite is incompatible with the Ubuntu target.
- **Sources**: [Tor Project installation instructions](https://support.torproject.org/little-t-tor/getting-started/installing/); [Tor Resolute repository](https://deb.torproject.org/torproject.org/dists/resolute/); [Tor relay post-install guidance](https://community.torproject.org/relay/setup/post-install/); repository `roles/tor/tasks/main.yml`, `roles/tor-relay/tasks/main.yml`, and `roles/tor-exit/tasks/main.yml`.

### Tor identity backup and age decryption

- **Decision**: Before erasure, create and verify an encrypted backup of the complete Tor `keys` directory for each node, then confirm each restored identity matches the expected fingerprint. Do not proceed if the backup is absent, undecryptable, or mismatched. For a suspected compromise, do not restore the affected node's identity.
- **Rationale**: Tor Project recommends backing up the complete `keys` directory (`/var/lib/tor/keys` on Debian/Ubuntu) in a secure location. The current `backup.yml` fetches only `ed25519_master_id_secret_key` and `secret_id_key`, so it does not implement that full-directory recommendation. The existing encrypted backup submodule must be checked against this recovery need before it can be trusted.
- **Age limitation**: The existing `.age` files are encrypted to an SSH public key. The official age documentation says SSH identities must be supplied as private key files; ssh-agent identities are unsupported. The operator's Bitwarden SSH integration therefore cannot be used directly by the `age` CLI. A protected private-key file or a newly established recovery recipient is required to validate and decrypt the existing backups. Keep any such file out of the repository and remove it after use.
- **Alternatives considered**: Restoring only the two currently backed-up files is not selected because Tor Project recommends backing up the complete directory. Rebuilding without a verified restore is not selected because it risks losing the established relay identity.
- **Sources**: [Tor Project relay key backup guidance](https://community.torproject.org/relay/setup/post-install/); [age SSH key documentation](https://github.com/FiloSottile/age/blob/main/README.md).

### Ubuntu release upgrade ordering

- **Decision**: Upgrade the provider's Ubuntu 24.04 image to Ubuntu 26.04 LTS before restoring Tor keys or applying Ansible configuration.
- **Rationale**: Ubuntu enabled the supported 24.04-to-26.04.1 LTS upgrade path on 2026-09-29. Finalizing the OS first means the Tor apt source and all Ansible-managed packages are configured once against `resolute`. Ubuntu's server guidance recommends `do-release-upgrade` and warns that third-party repositories commonly need to be re-enabled after a release upgrade; this workflow configures the Tor repository only after the OS upgrade.
- **Alternatives considered**: Configure all services on 24.04 and then perform a release upgrade, which would require revalidating service units and repositories after the OS change.
- **Sources**: [Ubuntu server upgrade guidance](https://ubuntu.com/server/docs/how-to-upgrade-your-release/); [Ubuntu announcement enabling 24.04 to 26.04.1 upgrades](https://lists.ubuntu.com/archives/ubuntu-announce/2026-September/000328.html).

### Scope and deployment shape

- **Decision**: Keep the migration within the existing playbooks and service roles. Apply the provider rebuild to the three active nodes as one planned fleet operation, with an explicit outage window and preflight gates.
- **Rationale**: The constitution permits all-target rollout, and the existing architecture assigns shared host setup, SSH, firewall, DNS, Tor, exporters, and reporting to separate roles. The provider rebuild erases VM data, so identity verification and provider/network details must be resolved before that step.
- **Alternatives considered**: One-node-at-a-time rollout is not required by project policy and would leave mixed OS/package configurations while the Tor repository and roles are being migrated.
- **Sources**: `.specify/memory/constitution.md`; `playbook.yml`; `inventory`; `ANSIBLE_RUNBOOK.md`.

## Repository-Specific Findings

- `inventory` targets three active hosts: two relays (`tor01.mtak.nl`, `tor02.mtak.nl`) and one exit (`tor03.mtak.nl`).
- `playbook.yml` applies the `base`, `ssh`, `iptables`, `haveged`, `unbound`, and `tor` roles to all nodes; relay and exit roles are selected by inventory group; exporters and reporting follow.
- `update.yml` applies `dist` upgrades to all hosts and checks for a reboot requirement. The policy remains latest available package versions.
- `roles/tor-relay` and `roles/tor-exit` own Tor configuration for their respective node classes. Other service responsibilities remain in their existing roles.
- Host variables contain the expected Tor fingerprints. They also list `CloudVPS.com` as provider, while the operator identified CloudServer as the actual provider; this metadata is not referenced by current tasks, but should be corrected or omitted if those values are maintained during the migration.
- No CI workflow or automated test suite was found. Validation is through Ansible syntax/connectivity/configuration checks and service-level outcomes in the feature spec.
