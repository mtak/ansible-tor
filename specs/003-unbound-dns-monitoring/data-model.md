# Data Model: Unbound Resolver Security and Exit DNS Monitoring

This feature manages configuration and aggregate operational signals; it does not introduce stored user records or query-level DNS data.

## Resolver Posture

Represents the intended and effective resolver state for one managed node.

| Field | Meaning | Validation |
|---|---|---|
| `node` | Inventory host that runs Unbound | Must refer to a host in the active managed inventory. |
| `listener_addresses` | Loopback addresses on which recursive DNS is accepted | Must contain only enabled loopback addresses for the node's address families. |
| `permitted_clients` | Client networks allowed to use recursion | Must be loopback-only. Other clients are refused. |
| `dnssec_validation` | Whether DNSSEC validation is active | Must be enabled with a usable trust anchor; permissive validation must be off. |
| `qname_minimisation` | Whether upstream queries use best-effort QNAME minimization | Must be enabled; strict mode is not required. |
| `outbound_source` | Source address selected by the operating system for an upstream query | Must be observable from the effective route; no fixed source address is configured by this feature. |
| `package_version` | Installed Unbound version | Must be the latest version available from configured supported repositories after the update process. |

The intended posture is expressed in Ansible role configuration and host/group variables. Effective runtime settings are verified because packaged defaults and other included configuration can affect the running service.

## Exit DNS Health Signal

Represents aggregate resolver health for one Tor exit node, sourced from Unbound statistics exposed by its exporter.

| Field | Meaning | Validation |
|---|---|---|
| `node` | Exit host to which the signal belongs | Must identify a monitored exit node. |
| `servfail_count` | Aggregate count of SERVFAIL answers | Monotonic counter; thresholding uses a rate or increase over a configured window. It does not identify the cause of failure. |
| `exporter_available` | Whether the exporter can scrape Unbound control statistics | Missing or false telemetry must be reported as a monitoring failure, never treated as healthy DNS. |
| `observed_at` | Time at which the signal was scraped/evaluated | Used to determine sustained threshold duration. |

The signal includes no QNAME, client address, individual query, or user identity. SERVFAIL may result from upstream timeouts, DNSSEC validation, or other resolution failures. This model deliberately represents a resolver failure condition rather than attributing a specific cause.

## DNS Alert

Represents an operator-facing aggregate resolver failure alert.

| Field | Meaning | Validation |
|---|---|---|
| `node` | Affected exit host | Required and stable across firing/resolution. |
| `signal` | Resolver signal that crossed its configured threshold | Includes SERVFAIL rate or missing/unavailable telemetry. |
| `observed_value` | Current aggregate value or rate | Must be presented with the configured threshold and evaluation window. |
| `state` | Pending, firing, or resolved alert state | SERVFAIL condition must persist beyond one hour before firing; a healthy next evaluation resolves it. |
| `guidance` | Short operator action | Must identify the resolver signal and suggest checking Unbound health, DNSSEC validation, upstream reachability, and the node route as appropriate. Must not include query data. |

Alerts are evaluated and delivered by the existing Prometheus-based monitoring service. This repository owns the rule definition and node-side telemetry configuration, not the external notification receiver.
