# Implementation Plan: Restrict Tor Control and Metrics Access

**Branch**: `002-restrict-tor-access` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-restrict-tor-access/spec.md`

## Summary

Restrict Tor's control interface to authenticated local clients and restrict the native metrics listener to the Prometheus scraper sources. Preserve the Tor exporter running as `debian-tor`, root-operated Nyx, and the current firewall access needed by monitoring. Use Tor cookie authentication for local control clients, make the Tor metrics policy agree with the deployment allowlist, and document the effective access policy and verification steps.

## Technical Context

**Language/Version**: Ansible YAML and Jinja2 templates; managed nodes run supported Debian or Ubuntu LTS releases.

**Primary Dependencies**: Ansible, Tor, Nyx, the existing `prometheus-tor-exporter` package, and the existing iptables role.

**Storage**: No new persistent application data. Tor's existing data directory holds its control authentication cookie.

**Testing**: Ansible syntax and rendered configuration review, followed by deployment-level access checks for Tor control and metrics. No automated test framework is present in the repository.

**Target Platform**: All active `all-servers` inventory nodes: two Tor relays and one Tor exit node.

**Project Type**: Ansible infrastructure configuration.

**Performance Goals**: Existing Tor metrics and exporter scraping continue at their current cadence without adding a monitoring outage during the configuration change.

**Constraints**: Tor control must not be remotely reachable; the `debian-tor` exporter and root Nyx must authenticate locally; the Tor metrics listener and firewall must admit only intended Prometheus sources; configuration must remain reproducible through Ansible and apply to both relay and exit templates.

**Scale/Scope**: Three active Tor nodes, two torrc templates, one shared Tor role, one exporter role, one firewall role, and repository operational documentation.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Service boundaries**: Pass. Tor listener and authentication settings belong to the Tor service configuration; exporter access belongs to its existing exporter configuration; network source filtering belongs to the iptables role. The policy documentation belongs in the runbook or README.
- **Reproducibility and replaceability**: Pass. All resulting state remains expressed in Ansible variables, templates, and roles.
- **Tor Project guidance**: Pass with the design decision to bind control locally, require cookie authentication, and use an explicit metrics allowlist. See [research.md](research.md).
- **User information minimization**: Pass. The change concerns service access only and adds no collection of user-specific information.
- **Operational simplicity**: Pass. No new component is proposed; existing Tor and firewall roles enforce the policy.

## Project Structure

### Documentation (this feature)

```text
specs/002-restrict-tor-access/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/                 # Not needed; this is internal node configuration
```

### Source Code (repository root)

```text
group_vars/all/                # Shared Tor and access policy variables
roles/tor/tasks/main.yml        # Tor and Nyx installation/configuration
roles/tor-relay/templates/torrc # Relay control and metrics listeners
roles/tor-exit/templates/torrc  # Exit control and metrics listeners
roles/prometheus-exporters/     # Local Tor exporter connection and service
roles/iptables/                 # Network-level metrics source filtering
ANSIBLE_RUNBOOK.md              # Deployment and access verification guidance
```

**Structure Decision**: Keep changes within the existing shared Tor, relay, exit, exporter, firewall, and runbook boundaries. Do not add a new project or public interface.

## Design Decisions

- Use a loopback-only Tor control listener with Tor cookie authentication, and verify the clients negotiate SAFECOOKIE. The exporter runs as `debian-tor`, while Nyx is configured for root; verify both clients can read/use Tor's cookie before rollout.
- Give native Tor MetricsPort a specific allow policy for Prometheus scraper sources and keep the host firewall allowlist consistent. The repository currently permits the configured `control_ipv4` and `control_ipv6` sources through the firewall, but it does not identify which of those are the scraper. Confirm and document that mapping before applying the policy; do not invent new source addresses.
- Keep the native Tor MetricsPort distinct from the exporter HTTP endpoint. Validate the former at port 9098 and the exporter endpoint at port 9099 so a passing exporter check cannot mask a blocked Tor metrics listener.
- Apply consistent behavior to both relay and exit torrc templates. Preserve local control and metrics access after service restart.

## Risks and Mitigations

- **Scraper addresses are not explicitly named in inventory**: Existing firewall variables are named `control_ipv4`/`control_ipv6` and shared with other administrative ports. Confirm which permitted addresses scrape port 9098 and record that mapping before rollout; keep unrelated admin sources out of the Tor metrics policy if they do not scrape it.
- **Cookie access breaks one local client**: Check exporter as `debian-tor` and Nyx as root after configuration; correct only the required local cookie access while preserving filesystem protection.
- **Metrics restriction blocks monitoring**: Validate the native Tor metrics port and exporter endpoint from the authorized scraper and verify an outside source is denied before considering deployment complete.
- **IPv4/IPv6 policy mismatch**: Inspect both rendered firewall families and each Tor listener/policy for the configured address families.

## Constitution Check (Post-Design)

- **Service boundaries**: Pass. The design assigns each setting to its current owning role and calls out the single policy boundary that must remain consistent between Tor and iptables.
- **Reproducibility, Tor guidance, privacy, and operational simplicity**: Pass. The plan introduces no new service, preserves the encrypted/reprovisionable node model, follows Tor control/metrics guidance, and adds no user data collection.

## Open Deployment Prerequisite

The actual Prometheus scraper source address(es) cannot be identified from this repository alone. The existing firewall allowlist is the available source of permitted addresses, but is also used for other administration. Before implementation is deployed, confirm which of those addresses scrape the native Tor metrics endpoint and use/document that exact set. This does not block design or plan generation.
