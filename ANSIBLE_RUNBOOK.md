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

## Tor Exit Operations (tor03)

### Scope and status terms

This review covers the seven ports configured in `group_vars/all/tor`: 53, 80,
443, 993, 995, 1194, and 11371. It records the observed policy and operational
readiness as checked on 2026-10-25. It does not change the active exit policy;
any policy change needs separate approval and rollout. No abuse response-time
target is set. Use these status terms consistently:

- **verified**: checked and supported by the stated observation.
- **not supported**: the protocol or record type is not supported for the stated
  purpose.
- **unavailable**: the check could not be performed or its source was unavailable.
- **unresolved**: available information does not establish the answer.

Do not collect or record Tor-user activity, destination histories, traffic
content, or connection histories. Keep private provider evidence and references
out of this repository. Record only statuses and non-sensitive follow-up.

### Exit policy review

The role template renders an `ExitRelay 1` policy that rejects the node's own
address, accepts each configured port, then rejects all other ports. The table
compares that policy with the comments in `group_vars/all/tor`. “Candidate keep”
records a review recommendation for the labeled service; it is not an assertion
that original operator intent has been confirmed or an active policy change.

All checks below were run directly from tor03 over TCP on 2026-10-25. A successful
TCP connection verifies a path to the named endpoint, not application-level
service operation or availability to every destination.

| Port | Intended service and rationale | Policy decision | Direct check from tor03 | Result and follow-up |
| --- | --- | --- | --- | --- |
| 53 | DNS over TCP; permits DNS queries that require TCP. | Candidate keep for TCP DNS; confirm this is intended alongside the local resolver. | `1.1.1.1:53`, TCP; `nc` and `dig +tcp`; resolver check separately used `127.0.0.1` for `torproject.org`. | **verified**: TCP connection and DNS query succeeded; local resolver resolved the name. |
| 80 | HTTP; supports ordinary web connections. | Candidate keep; purpose follows the configured web service port. | `example.com:80`, TCP; `nc`. | **verified**: TCP connection succeeded. |
| 443 | HTTPS; supports encrypted web connections. | Candidate keep; purpose follows the configured web service port. | `example.com:443`, TCP; `nc`. | **verified**: TCP connection succeeded. |
| 993 | IMAPS; encrypted IMAP access. | Candidate keep; `group_vars/all/tor` labels this IMAPS. | `imap.gmail.com:993`, TCP; `nc`. | **verified**: TCP connection succeeded. |
| 995 | POP3S; encrypted POP3 access. | Candidate keep; `group_vars/all/tor` labels this POP3S. | `pop.gmail.com:995`, TCP; `nc`. | **verified**: TCP connection succeeded. |
| 1194 | Commented as OpenVPN, commonly used with UDP by default; OpenVPN can also use TCP. Tor exit streams support TCP, not UDP. | **unresolved**: confirm the intended OpenVPN transport and purpose before deciding. No policy change made. | `portquiz.net:1194`, TCP; `nc`. This is a generic TCP connectivity endpoint, not an OpenVPN service endpoint. | **verified** for TCP path connectivity only. OpenVPN service and intended transport remain unresolved; confirm with the operator and test an intended TCP service endpoint if TCP is intended. |
| 11371 | OpenPGP HKP key-server access; `group_vars/all/tor` labels this OpenPGP HKP. | Candidate keep; confirm the service remains needed. | `keys.openpgp.org:11371`, TCP; `nc`. | **verified**: TCP connection succeeded. |

The comments identify IMAPS, POP3S, OpenVPN, and OpenPGP HKP. They do not
document the original rationale for ports 53, 80, or 443; the purposes above are
service-level rationale, not evidence of operator intent. Confirm that all
candidate-keep entries remain needed during the next policy review. Do not infer
UDP reachability from any TCP result.

### Abuse notice handling and provider escalation

The Tor configuration includes operator contact information. The local aliases
template routes `abuse` to `root`, then routes `root` through the configured
notification address. This establishes configured routing only; mailbox receipt
and delivery have not been tested. Do not copy the configured address into this
operational record. Follow up by having the operator confirm that the mailbox is
monitored and receives mail.

For an abuse notice:

1. Preserve only the notice's operational details needed to identify the relay,
   reported time range, complaint category, and a safe reply route. Do not
   solicit or retain Tor-user identity, destination lists, content, or connection
   history. Handle any personal information only as needed to answer the notice.
2. Compare the report with the relay's public identity and configuration. Note
   whether it appears to describe exit traffic and whether the report supplies
   enough information to assess it. Do not claim that a particular user or
   connection caused the reported activity.
3. Reply through the notice's provided route with a factual explanation that
   tor03 is a Tor exit relay, the limits of attribution, and any operational
   action actually taken. Do not promise a response deadline.
4. Contact the hosting provider if the notice indicates a provider request,
   suspension risk, network-level action, or a host/configuration issue. First
   verify the provider identity and the account's current support route; those
   are unresolved below. Provide only the notice reference supplied by the
   reporter, relay IP/hostname, relevant dates, and operational facts needed for
   that provider action. Do not provide or create Tor-user activity records.
5. Keep a minimal operational note: date received, complaint category, relay,
   triage status, response/escalation action, outcome, and any follow-up owner
   or action. Do not retain a full complaint copy in this repository.

The provider identity/contact route is not established by the available public
and repository information. Until it is verified, escalate through the account
owner's known provider account channel after confirming the contracting entity;
do not assume a public abuse mailbox is the correct route for this customer.

The required timed walkthrough by a maintainer unfamiliar with current practice
has not yet been performed. Before treating this procedure as operationally
accepted, ask such a maintainer to follow the steps above with a hypothetical
notice and record whether they identify intake, next action, and escalation
decision within 10 minutes. This is a usability check, not a response-time target.

### Identity and provider readiness

Checks dated 2026-10-25:

| Check | Status and observation | Follow-up |
| --- | --- | --- |
| Reverse DNS | **verified**: tor03's observed public IPv4 address `198.46.166.157` has PTR `tor03.mtak.nl.`; it does not identify the host as a Tor exit relay. No AAAA address was observed. | Consider a relay-identifying PTR if operationally appropriate and supported by the network owner. |
| Public registration (WHOIS) | **verified**: the more specific public range is `198.46.166.128–198.46.166.159`, registered under `CC-198-46-166-0-27`, US; the covering range is under HostPapa (`CC-13`). The record does not identify the host as a Tor exit relay. | Confirm the contracting provider and network operator. |
| Provider identity | **unresolved**: repository host variables name CloudVPS.com, while public IP registration names HostPapa. `cloudvps.com` currently redirects to TransIP; this does not establish which entity holds this host's account. | Account owner to confirm the contracting entity and current support channel. |
| Dedicated host | **unresolved**: no account-level or other reliable evidence was available for this check. | Account owner to verify whether this machine is dedicated. |
| Permission for Tor exit operation | **unresolved**: no applicable account terms or provider confirmation could be tied to the host. Publicly available generic hosting terms do not establish permission for this account. | After provider identity is confirmed, check applicable terms or ask the provider directly. |
| Provider support/contact route | **unresolved**: no verified account support route is available in the repository or public registration record. | Account owner to verify the customer support/escalation route and whether exit-relay issues are supported. |

Do not add private account details, correspondence, or references when these
follow-ups are completed. Update each status and check date from the result.
