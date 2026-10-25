# Data Model: Exit Relay Operations Review

This feature adds no database or structured runtime storage. The following records describe the minimum information the operator procedure and its repository documentation need to cover.

## Exit Port Review

One entry for each configured port on tor03.

| Field | Meaning | Validation |
|---|---|---|
| `port` | Configured destination port | Unique; one of 53, 80, 443, 993, 995, 1194, or 11371 for this review |
| `intended_service` | Human-readable service purpose | Must be reviewed rather than inferred only from a port number or comment |
| `transport` | Protocol used for the reachability check | Record TCP for Tor exit stream checks; distinguish host-level UDP checks from Tor exit reachability |
| `policy_rationale` | Why the service should be allowed | Must explain the operator's keep-or-change decision |
| `decision` | Keep, recommend change, or unresolved | Recommendations do not change active policy; changes require separate approval |
| `check_method` | Direct connection check from tor03 to the intended service endpoint | Record the destination and transport; an end-to-end Tor-client check is not required for acceptance |
| `check_result` | Verified, not supported, unavailable, or unresolved | Must not imply broader reachability than the check established |
| `checked_on` | Date of the check | Required for each check result |
| `follow_up` | Action needed to resolve a failed or incomplete check | Required where the status is not verified |

The port 1194 comment currently says OpenVPN. The review must identify whether the intended service uses TCP or UDP; a UDP-only service is not reachable as a standard Tor exit stream.

## Public Relay Identity Check

One dated check per applicable public identity record type.

| Field | Meaning | Validation |
|---|---|---|
| `record_type` | Reverse DNS, WHOIS, or equivalent public registration record | Identify unsupported record types explicitly |
| `status` | Verified, not supported, unavailable, or unresolved | Use the same status vocabulary as other external checks |
| `observed_result` | Public record content or concise result | Include only shareable public information needed to assess relay identity |
| `checked_on` | Date the record was checked | Required |
| `follow_up` | Any needed correction or further check | Required unless the result is verified or unsupported with no alternative |

## Provider Readiness Status

Record separate statuses for dedicated-host status, provider permission for exit relay operation, and provider support/contact route.

| Field | Meaning | Validation |
|---|---|---|
| `readiness_item` | Dedication, permission, or support | Each item is assessed separately |
| `status` | Verified, not supported, unavailable, or unresolved | Do not infer verification from Ansible configuration or provider name |
| `checked_on` | Date checked | Required |
| `follow_up` | What remains to be confirmed or addressed | Required when the result is not verified |

Repository documentation contains only the status, date, and any non-sensitive follow-up. It contains no private provider account details, correspondence, evidence excerpt, or reference to restricted evidence.

## Abuse Notice Handling Record

The runbook defines how to handle notices; it does not introduce a new complaint database. If an operator needs a minimal operational note to coordinate a response, it may cover:

- Received date and intake route
- Broad complaint category and triage state
- Whether a response was sent
- Whether provider escalation was needed and its outcome
- A non-sensitive follow-up action

Do not copy full complaint content into repository documentation. Do not record Tor user identity, destination addresses, traffic content, or connection-level history. The procedure sets no response-time target.

## Relationships

- One exit policy review contains seven Exit Port Review entries.
- One relay identity review may contain reverse DNS and applicable registration checks.
- One provider readiness review contains separate dedication, permission, and support statuses.
- Abuse notices follow the same documented process; any operational note remains minimal and does not join a notice to specific Tor user activity.
