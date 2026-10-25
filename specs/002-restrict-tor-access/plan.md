# Implementation Plan: Restrict Tor Control and Metrics Access

**Branch**: `002-restrict-tor-access` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-restrict-tor-access/spec.md`

## Summary

Restrict Tor's control interface to authenticated local clients and restrict the native metrics listener to the existing `control_ip` allowlist. Preserve the Tor exporter running as `debian-tor` and root-operated Nyx. Use Tor cookie authentication for local control clients, align Tor's native metrics policy with the existing source allowlist and firewall, leave the Prometheus-to-exporter HTTP path unchanged, and document the effective policy.

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

- Use a loopback-only Tor control listener with Tor cookie authentication and verify the exporter negotiates SAFECOOKIE. The exporter runs as `debian-tor`; Nyx is configured for root, and its runtime check will be performed by the operator separately.
- Give native Tor MetricsPort an explicit allow policy using the existing `control_ip` source set. The firewall already restricts inbound ports 9098 and 9099 to this set, so no change to the Prometheus-to-exporter HTTP path or firewall source list is required.
- Keep the native Tor MetricsPort distinct from the exporter HTTP endpoint. Validate the former at port 9098 and the exporter endpoint at port 9099 so a passing exporter check cannot mask a blocked Tor metrics listener.
- Apply consistent behavior to both relay and exit torrc templates. Preserve local control and metrics access after service restart.

## Risks and Mitigations

- **The allowlist is shared with administration**: `control_ip` also permits other operational traffic. Keep Tor's native MetricsPort policy at the same existing allowlist for this change, and don't expand that list.
- **Cookie access breaks one local client**: Check exporter as `debian-tor` after configuration; the operator will separately validate Nyx as root. Correct only the required local cookie access while preserving filesystem protection.
- **Metrics restriction blocks monitoring**: Validate the native Tor metrics port and exporter endpoint from the authorized scraper and verify an outside source is denied before considering deployment complete.
- **IPv4/IPv6 policy mismatch**: Inspect both rendered firewall families and each Tor listener/policy for the configured address families.

## Constitution Check (Post-Design)

- **Service boundaries**: Pass. The design assigns each setting to its current owning role and calls out the single policy boundary that must remain consistent between Tor and iptables.
- **Reproducibility, Tor guidance, privacy, and operational simplicity**: Pass. The plan introduces no new service, preserves the encrypted/reprovisionable node model, follows Tor control/metrics guidance, and adds no user data collection.

## Deployment Scope

Use the existing `control_ip` source allowlist for Tor's native MetricsPort policy. Keep the existing firewall rules for 9098 and 9099 and the Prometheus-to-exporter endpoint unchanged. Nyx remains an authorized local client; its runtime validation is handled by the operator outside the task checklist.
