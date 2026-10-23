# Quickstart: Ubuntu Node Rebuild Validation

This guide describes validation for the planned migration. It does not perform a provider rebuild. The provider's rebuild action erases the selected VM's data. The provider supplies Ubuntu 24.04 LTS; upgrade to Ubuntu 26.04 LTS before restoring Tor keys or running Ansible.

## Prerequisites

- Run commands from the repository root with the `inventory` file explicitly selected.
- Use the controller environment recorded in `ANSIBLE_RUNBOOK.md` if its temporary paths or SSH configuration require those workarounds.
- Confirm the provider's image is Ubuntu 24.04 LTS and record each assigned public address. After bootstrap, upgrade and reboot to Ubuntu 26.04 LTS, then confirm `/etc/os-release` reports `VERSION_CODENAME=resolute` before configuring Tor.
- Verify a complete encrypted Tor `keys` backup for every node can be restored and that its fingerprint matches the corresponding host variable. For the existing SSH-recipient `.age` files, age requires a private-key file; an SSH-agent-only Bitwarden integration is insufficient. Do not erase a VM unless this check passes.
- Confirm the expected outage window and whether DNS/configuration need an address update.

## Preflight checks

List the targets and inspect their current operating system without requiring remote Python:

```sh
ansible -i inventory all-servers --list-hosts
ansible -i inventory all-servers -m raw \
  -a 'cat /etc/os-release; python3 --version' --timeout 10
```

After the provider has installed Ubuntu 24.04, the OS has been upgraded to Ubuntu 26.04, and bootstrap SSH access is available, check Ansible module connectivity:

```sh
ansible -i inventory all-servers -m ping --timeout 10
```

Check playbook syntax locally before applying configuration:

```sh
ansible-playbook -i inventory playbook.yml --syntax-check
```

## Configuration and service validation

Apply the planned Ansible configuration only during the approved maintenance window:

```sh
ansible-playbook -i inventory playbook.yml
```

Then verify per host that the Tor, Unbound, node exporter, and Tor exporter services are active; the two relay nodes reject exit traffic; the exit node applies its configured port and blocked-host policy; and each Tor relay reports successful external ORPort self-testing. Confirm that the report role completes for all three hosts and that routine recovery fingerprints match the pre-rebuild records.

Do not report fleet recovery as complete if any node fails configuration, identity verification, role checks, or external reachability.
