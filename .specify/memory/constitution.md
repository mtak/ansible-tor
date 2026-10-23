<!--
Sync Impact Report
- Version change: 1.2.0 → 2.0.0 (redefined the required node operating systems)
- Modified principles: Operational Policies (Debian-only → Debian or Ubuntu LTS)
- Added sections: Operational Policies
- Removed sections: none
- Updated Clarifications with the accepted Ubuntu LTS platform policy
- Follow-up TODOs: none
-->
# Ansible Tor Constitution

## Core Principles

### I. Preserve Service Boundaries
Changes MUST follow the existing Ansible service boundaries: shared host setup belongs
in `roles/base`, and service-specific configuration belongs in the role for that
service. A change that crosses these boundaries MUST explain why the existing role
cannot own it. This keeps node configuration understandable and independently
maintainable.

### II. Keep Nodes Reproducible and Replaceable
Managed node state MUST be expressible through the repository's Ansible inventory,
variables, playbooks, roles, handlers, and templates. A node MUST remain recoverable
by running Ansible, consistent with the repository's design that nodes are expendable
and can be reconfigured after failure or compromise.

### III. Respect Tor Project Guidance
Changes to Tor relay and exit configuration MUST follow applicable Tor Project
recommendations. Changes that depart from those recommendations MUST document the
reason in the relevant change proposal or repository documentation.

### IV. Minimize Stored User Information
Monitoring and reporting MUST remain limited to aggregate system health and Tor
operational metrics. They MUST NOT add collection or storage of specific user
information, consistent with the documented purpose of the existing Prometheus
exporters.

### V. Keep Operational Changes Understandable
Changes MUST fit the existing Ansible and service-role structure and be no broader
than needed for the operational purpose. New components or cross-role mechanisms
MUST state the operational need they address so maintainers can assess their cost
and effect on node recovery.

## Architecture Boundaries

The repository configures Tor relay and exit nodes. Its existing roles define the
boundaries for shared host setup, Tor, networking, DNS, SSH, exporters, and reporting.
Plans MUST identify the owning role and any affected service boundary before
proposing changes that span roles. Node-specific configuration belongs in inventory
or host/group variables where the existing layout provides for it.
Changes may be applied to all targeted nodes in the same rollout; the project does
not require one-node-at-a-time deployment.

## Operational Policies

Managed nodes MUST run a supported Debian release or Ubuntu LTS release. The supported
release may change as the deployment evolves. Ansible-managed packages MUST use the
latest available versions, consistent with the existing roles and update playbook.

Tor identity keys MUST be preserved in encrypted backups for routine recovery. If a
node is suspected to be compromised, recovery MUST provision new identity keys and
MUST NOT restore that node's backed-up identity keys.

## Contribution and Review

Contributions MUST describe the operational behavior they change and the roles,
playbooks, variables, or templates affected. Review MUST consider whether the change
preserves service boundaries, node reproducibility, Tor guidance, and the restriction
on user-specific monitoring data. The repository describes external pull requests
as welcome for consideration but low priority; it does not define mandatory CI or
test gates, so this constitution does not impose any.

## Governance

This constitution guides feature specifications, plans, implementation, and their
review. A proposal that conflicts with a principle MUST identify the conflict and
justify the exception for review before the conflicting change is accepted.

Amendments MUST update this document and explain the change in its review. Versioning
uses semantic versioning: MAJOR for incompatible principle changes, MINOR for new
principles or materially expanded obligations, and PATCH for clarifications that do
not change obligations. Reviewers MUST check proposed work against the applicable
principles and the repository evidence cited by them. No specific test or CI gate is
required unless the repository adopts one.

## Clarifications

### Session 2026-10-23
- Q: What ratification date should the constitution record? → A: 2026-10-23, the date the constitution was drafted.
- Q: When a playbook change affects multiple Tor nodes, should deployment proceed one node at a time to keep the other nodes serving traffic? → A: Apply changes to all targeted nodes together.
- Q: Should future playbooks continue installing or upgrading packages to the latest available versions, as the current roles and update playbook do? → A: Continue using the latest available versions.
- Q: Should encrypted backups preserve Tor identity keys for routine recovery, with new keys used if a node’s compromise is suspected? → A: Preserve keys for routine recovery; rotate after suspected compromise.
- Q: Should future plans treat Debian as the required node operating system while allowing its release to change over time? → A: Require Debian; select the release as needed.
- Q: Should the constitution permit Ubuntu LTS as a managed node operating system alongside Debian? → A: Yes; Debian and Ubuntu LTS are both allowed.

**Version**: 2.0.0 | **Ratified**: 2026-10-23 | **Last Amended**: 2026-10-23
