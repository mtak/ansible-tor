# Quickstart: Validate Tor Access Restrictions

This guide is for validating an implementation after it has been reviewed and deployed. Do not use the full playbook as a connectivity check; it changes node configuration. Follow [ANSIBLE_RUNBOOK.md](../../ANSIBLE_RUNBOOK.md) for controller setup and deployment expectations.

## Prerequisites

- Confirm the Prometheus scraper source address(es) authorized for native Tor metrics and that they match the documented allowlist.
- Have access to one active relay and one active exit node, plus the Prometheus scraper and a test source outside its allowlist.
- Confirm the intended rollout and review the Ansible diff before applying it.

## Validation scenarios

1. **Configuration review**: Inspect the rendered Tor configuration and both IPv4 and IPv6 firewall rules on each node. Confirm ControlPort is local only and authenticated, local clients negotiate SAFECOOKIE, native MetricsPort is restricted to the confirmed scraper sources, and no broad `accept *` rule remains.
2. **Exporter control access**: Check that `prometheus-tor-exporter` is active and can reconnect as `debian-tor` to the local Tor control interface. Confirm its HTTP metrics endpoint on port 9099 responds to the authorized monitoring source.
3. **Nyx operator access**: Run Nyx as the root operator on a node. Confirm it connects to Tor and can display status and configuration panels using local authenticated control access.
4. **Native metrics allowlist**: Request the Tor metrics endpoint on port 9098 from each authorized scraper source and confirm a successful metrics response. Repeat from a source outside the allowlist and confirm the request is denied.
5. **Service recovery**: After a planned Tor restart, repeat the exporter and Nyx checks and confirm authorized scraping resumes without a policy change.
6. **Policy documentation**: Confirm the runbook names the control boundary, local authenticated clients, native metrics port, and exact authorized scraper addresses/address families.

## Expected result

All unauthorized control and metrics attempts are denied, Nyx and the exporter retain their local control functions, and authorized Prometheus scraping continues for both the native Tor metrics listener and the exporter endpoint.
