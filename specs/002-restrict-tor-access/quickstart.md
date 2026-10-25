# Quickstart: Validate Tor Access Restrictions

This guide is for validating an implementation after it has been reviewed and deployed. Do not use the full playbook as a connectivity check; it changes node configuration. Follow [ANSIBLE_RUNBOOK.md](../../ANSIBLE_RUNBOOK.md) for controller setup and deployment expectations.

## Prerequisites

- Confirm the `control_ip` source set used by the existing firewall rules for native Tor metrics.
- Have access to one active relay and one active exit node, plus the Prometheus scraper and a test source outside its allowlist.
- Confirm the intended rollout and review the Ansible diff before applying it.

## Validation scenarios

1. **Configuration review**: Inspect the rendered Tor configuration and both IPv4 and IPv6 firewall rules on each node. Confirm ControlPort is `127.0.0.1:9051` with cookie authentication, MetricsPort binds to the node's primary IPv4 address, the policy uses the `control_ipv4` and `control_ipv6` values, and no broad `accept *` metrics policy remains.
2. **Control denial**: From a remote source, attempt to connect to ControlPort and confirm it is unreachable. From the node, attempt a control command without authenticating and confirm Tor rejects it.
3. **Exporter control access**: Check that `prometheus-tor-exporter` is active and can reconnect as `debian-tor` to the local Tor control interface using SAFECOOKIE. Leave its existing HTTP metrics endpoint on port 9099 and firewall access unchanged.
4. **Native metrics allowlist**: Request the Tor metrics endpoint on port 9098 from a source in `control_ip` and confirm a successful metrics response. Repeat from a source outside the allowlist and confirm the request is denied.
5. **Service recovery**: After a planned Tor restart, repeat the exporter and authorized metrics checks and confirm collection resumes without a policy change.
6. **Policy documentation**: Confirm the runbook names the local control boundary, authentication, native metrics port, and effective IPv4/IPv6 source addresses from the `control_ip` variables.

## Expected result

All unauthorized control and metrics attempts are denied, the exporter retains its local control connection, and authorized Prometheus scraping continues for the native Tor metrics listener. The existing Prometheus-to-exporter endpoint remains unchanged. Nyx runtime validation is performed separately by the operator.
