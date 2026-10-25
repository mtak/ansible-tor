# Ansible Runbook

This runbook records the controller setup and read-only checks used to establish
contact with the nodes. Run commands from the repository root. The inventory file
is named `inventory`, so pass `-i inventory` explicitly.

## Read-Only Connectivity Baseline

Start by confirming the controller version and the inventory target list:

```sh
ansible --version
ansible -i inventory all-servers --list-hosts
```

The active `all-servers` inventory group currently contains the relay nodes
`tor01.mtak.nl` and `tor02.mtak.nl`, and exit node `tor03.mtak.nl`.

In a normal writable controller environment, check SSH and remote Python with:

```sh
ansible -i inventory all-servers -m ping
```

The ping module needs a usable Python interpreter on each managed host. If it fails
while parsing the transferred module, use Ansible's `raw` module to check SSH and
inspect the host without requiring remote Python:

```sh
ansible -i inventory all-servers -m raw \
  -a 'python3 --version; cat /etc/os-release' --timeout 10
```

`raw` reports `CHANGED` even when the shell command only reads state. The command
above does not make configuration changes.

## Controller Temporary Paths

In the constrained controller environment used for the 2026-10-23 baseline,
`/home/mtak/.ansible` was read-only. Set Ansible's local module temp directory and
SSH control socket directory to writable temporary paths:

```sh
mkdir -p /tmp/ansible-control
export ANSIBLE_LOCAL_TEMP=/tmp
export ANSIBLE_SSH_CONTROL_PATH_DIR=/tmp/ansible-control
```

Retry the inventory and connectivity commands with these variables set. Setting
`ANSIBLE_HOME` alone did not change the SSH control socket path in this environment.

The system SSH configuration also failed validation because
`/etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf` had unacceptable ownership or
permissions. The successful connection check bypassed SSH configuration:

```sh
export ANSIBLE_SSH_COMMON_ARGS='-F /dev/null'
```

This is an environment-specific workaround. It ignores SSH configuration, including
host aliases, proxy settings, and identity settings. Use it only when the default
SSH connection works without those settings. Otherwise fix the SSH configuration
permissions or supply an appropriate SSH config file rather than bypassing it.

With the workarounds above, the commands used were:

```sh
ansible -i inventory all-servers --list-hosts
ansible -i inventory all-servers -m ping --timeout 10
ansible -i inventory all-servers -m raw \
  -a 'python3 --version; cat /etc/os-release' --timeout 10
```

## Baseline Recorded on 2026-10-23

- SSH reached all three active inventory hosts.
- All three hosts reported Debian GNU/Linux 10 (Buster) and Python 3.7.3.
- The controller had ansible-core 2.21.4 and Python 3.14.4.
- The ping module could not run: the transferred module contains Python syntax not
  supported by Python 3.7. The remote raw command worked without a remote Python
  module.
- Ansible warned about invalid characters in inventory group names and deprecated
  `jinja2_extensions` and `ansible_managed` settings.
- SSH reported that the connection did not use a post-quantum key exchange. This
  was a warning, not a connection failure.

## Before Running a Playbook

Do not use `playbook.yml` as a connectivity check. It applies host configuration,
installs packages, changes firewall and service configuration, and may restart
services. The baseline above did not run a playbook or change node configuration.

For the planned Ubuntu migration, verify that each upgraded node reports Ubuntu
26.04 LTS (`VERSION_CODENAME=resolute`) and a supported Python interpreter before
using Ansible modules. The Tor repository role uses the distribution codename and
a repository-scoped signing key. The relay and exit roles manage the actual
`tor@default` daemon unit.

A successful SSH or raw check does not mean Ansible modules or the full playbook
will run successfully. Review the target list and expected changes, then run a
playbook only as an explicitly planned deployment.

## Tor Control and Metrics Access

Tor's control interface listens only on `127.0.0.1:9051` and requires cookie
authentication. The local Tor exporter connects to that interface as
`debian-tor` and authenticates with SAFECOOKIE. Nyx is an operator interface
used locally as root.

Tor's native Prometheus metrics listener uses port `9098` and binds to the node's
primary IPv4 address. Its access policy and the host firewall use the same source
allowlist. The current values in `group_vars/all/external` are:

- IPv4 (`control_ipv4`): `82.170.63.141`, `141.144.203.6`, `84.235.164.75`
- IPv6 (`control_ipv6`): `2a02:a469:cb84::/64`

Only those sources are accepted by Tor's metrics policy. The existing firewall
also restricts port `9098` to that source set. The exporter HTTP endpoint on
port `9099` remains a separate path and its firewall rule is unchanged.

## Unbound Resolver Policy and Exit DNS Alerts

The Unbound role installs a node-local resolver policy at
`/etc/unbound/unbound.conf.d/resolver-policy.conf`. The policy binds recursive DNS
to loopback, enables DNSSEC validation and QNAME minimization, and leaves outbound
source selection to the operating system. Validate the rendered configuration with
`unbound-checkconf` before restarting Unbound. The Unbound package task refreshes
apt metadata when it is older than one hour before selecting the latest available
package.

The repository-managed Prometheus rules are in
`monitoring/prometheus/tor-exit-dns.rules.yml`. The repository does not manage the
external Prometheus scrape configuration, rule-import path, or notification
receiver. Before importing, the monitoring owner must confirm the target selector
for the active exit (`tor03.mtak.nl`) and the rule import path. The current rule
assumes `instance="tor03.mtak.nl:9167"`; change it to match the actual scrape
labels if needed. Its initial SERVFAIL threshold of `0.1` responses/second is
provisional because no baseline series is stored in this repository. Review it
against observed aggregate metrics before enabling notifications.

Validate the rule file with the external Prometheus rule checker and the service's
existing notification path. A sustained SERVFAIL rate above threshold fires after
one hour; the first healthy evaluation resolves it. Missing or unavailable
`unbound_up` telemetry produces a separate monitoring alert. SERVFAIL is a broad
resolver failure signal and does not prove an upstream timeout. Check Unbound
health, DNSSEC validation, upstream reachability, and the node route as appropriate.
