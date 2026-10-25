# Implementation Plan: Exit Relay Operations and Policy Review

**Branch**: `004-exit-relay-operations` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-exit-relay-operations/spec.md`

## Summary

Update the operational runbook with an evidence-based review procedure for tor03's seven configured exit ports, abuse notice handling, public relay identity, host dedication, and provider support. Use the existing Ansible variables and Tor Project guidance as review inputs. Keep the active exit policy unchanged; any proposed policy change requires separate approval. Record provider readiness as a status, check date, and any non-sensitive follow-up, without private provider evidence or references.

## Technical Context

**Language/Version**: Markdown documentation; existing Ansible YAML is read as configuration context only

**Primary Dependencies**: Existing `inventory`, `group_vars/all/tor`, `host_vars/tor03.mtak.nl`, and `roles/tor-exit/templates/torrc`; official Tor Project operator guidance

**Storage**: Existing Markdown runbook; no new data store. Public DNS/registration findings may include shareable record evidence; provider readiness records status, check date, and non-sensitive follow-up only.

**Testing**: Manual review of all seven ports, direct TCP reachability checks from tor03, public-record checks, procedure walk-through, and documentation review. A direct node-level connection check is sufficient for acceptance; no end-to-end Tor-client test is required. No automated test gate is required by the project constitution.

**Target Platform**: Repository maintainers and operators of the Ansible-managed Tor exit node `tor03.mtak.nl`

**Project Type**: Operational documentation for an Ansible-managed Tor exit relay

**Performance Goals**: Not applicable to this documentation change

**Constraints**: Do not change the active exit policy; do not set an abuse response time target; do not store Tor-user activity or private provider evidence or references in repository documentation; record provider status, check date, and non-sensitive follow-up only; mark unavailable or unsupported checks explicitly. Use direct TCP reachability checks from tor03 for the accepted reachability result; do not treat UDP reachability as Tor exit reachability.

**Scale/Scope**: One exit relay, seven configured destination ports, one hosting arrangement, and the operating procedure for abuse notices

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle or boundary | Plan assessment | Gate |
|---|---|---|
| Preserve service boundaries | The change belongs in operator documentation. It does not change the Tor exit role, shared host configuration, or another service role. | PASS |
| Keep nodes reproducible and replaceable | No node state is changed. The existing Ansible configuration remains the source of truth; any future policy change is separately approved and expressed through existing configuration. | PASS |
| Respect Tor Project guidance | Review policy purpose and reachability against official guidance; document evidence and recommendations. Do not claim Tor supports UDP exit traffic. | PASS |
| Minimize stored user information | Document complaint handling without collecting or retaining specific user traffic or destination details. | PASS |
| Keep operational changes understandable | Add one focused runbook section; no new component, role, or cross-role mechanism. | PASS |
| Architecture boundaries | No role boundary is crossed; the runbook links policy checks to existing exit configuration. | PASS |

**Gate result before research**: PASS. No exceptions or complexity entries are required.

## Project Structure

### Documentation (this feature)

```text
specs/003-exit-relay-operations/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/       # Not needed: this feature defines no machine interface
```

### Repository files relevant to the feature

```text
ANSIBLE_RUNBOOK.md                  # Add the operator review and response procedure
group_vars/all/tor                  # Read-only source for the seven configured ports
host_vars/tor03.mtak.nl             # Read-only hosting-provider context
roles/tor-exit/templates/torrc      # Read-only source for relay identity and exit policy rendering
```

**Structure Decision**: Keep the operator-facing procedure in the existing `ANSIBLE_RUNBOOK.md`, which already records controller checks and node operations. Treat the Ansible variables and Tor template as sources to inspect, not files to modify for this feature. No `contracts/` directory is generated because the feature exposes no API, command interface, or service contract.

## Complexity Tracking

No constitution violations or added architectural complexity.

## Phase 0: Research Summary

Research decisions and source links are recorded in [research.md](research.md). Research confirms that a Tor exit policy describes destination ports but Tor exit streams use TCP. This affects the reachability method for each entry: the review must record transport as well as port. In particular, the existing comment labels port 1194 as OpenVPN; if the intended service is UDP-only, Tor clients cannot use it through the standard Tor exit stream path, so record that limitation and recommend a decision without changing configuration.

## Phase 1: Design Summary

- [data-model.md](data-model.md) defines the review record, provider readiness statuses, and minimal abuse-notice handling record.
- [quickstart.md](quickstart.md) defines read-only checks and acceptance walkthroughs for the maintainer and operator.
- No interface contracts are needed: this change adds documentation and manual operational checks only.

## Constitution Check After Design

| Principle or boundary | Design assessment | Gate |
|---|---|---|
| Preserve service boundaries | One runbook section owns the operator procedure; service configuration stays in the existing exit role and variables. | PASS |
| Keep nodes reproducible and replaceable | Checks are read-only. A recommendation does not alter node state; a future change follows normal Ansible configuration and rollout. | PASS |
| Respect Tor Project guidance | Port decisions use official exit-policy guidance and transport-aware checks. Any departure or proposed change is documented for separate approval. | PASS |
| Minimize stored user information | The procedure excludes user traffic details and does not add activity logging. | PASS |
| Keep operational changes understandable | The plan adds no services or operational components and keeps status recording deliberately small. | PASS |
| Architecture boundaries | No roles, playbooks, or service interfaces are changed. | PASS |

**Gate result after design**: PASS. Implementation planning can proceed to task generation.
