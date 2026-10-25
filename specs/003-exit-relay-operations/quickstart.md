# Quickstart: Validate Exit Relay Operations Documentation

This guide describes read-only review scenarios for the tor03 exit operations update. It does not deploy Ansible changes or modify the active exit policy.

## Prerequisites

- Repository checkout with the `inventory` file and Ansible configuration available.
- Operator access to tor03 for read-only checks, plus the relay's public IP address.
- A known destination that offers each service being checked. Do not treat an endpoint that does not offer the service as evidence about the exit relay.
- Access to provider terms/account for private readiness checks. Record only the resulting status in repository documentation; keep private evidence and references outside it.
- `dig`, `whois` (or an equivalent public registration lookup), and a TCP connection checker such as `nc` for the corresponding checks.

## 1. Confirm the review scope

From the repository root, inspect the configured ports and their current comments:

```sh
sed -n '/^tor_exit_ports:/,/^[^[:space:]#]/p' group_vars/all/tor
```

Expected review scope: 53, 80, 443, 993, 995, 1194, and 11371. Compare against the exit policy rendered by the Tor role on tor03 before recording the review. Do not edit configuration during this feature.

## 2. Record purpose and check TCP reachability per port

For each port, identify an endpoint that offers the intended service and run the check from tor03:

```sh
nc -vz -w 5 <service-hostname-or-address> <port>
```

Record the destination/service, transport (TCP), check location, result, and date for every port. A direct connection check from tor03 is sufficient reachability evidence for this review; an end-to-end Tor-client test is not required. A timeout from one endpoint or location is limited evidence; record the limitation and retry/follow-up as appropriate.

Port 53 needs two distinct considerations: verify that the relay's configured resolver can resolve a known public name, and test TCP destination port 53 only if the policy intends to allow DNS-over-TCP streams. For port 1194, determine whether OpenVPN is intended to use TCP. If it is UDP-only, record UDP as unsupported for standard Tor exit streams and do not mark it as Tor-reachable based on a host-level UDP test.

## 3. Check public relay identity records

For the public IP assigned to tor03, run:

```sh
dig -x <tor03-public-ip> +short
whois <tor03-public-ip>
```

Record the reverse-DNS and applicable public registration result, date, and whether the record identifies the exit relay. Mark unsupported or unavailable record types explicitly. Include only public, shareable record details in the repository.

## 4. Check provider readiness

In the provider's terms/account or through its support channel, check dedicated-host status, permission to operate a Tor exit relay, and the provider's support/contact route. In the repository, record each item's status and check date, plus any non-sensitive follow-up. Do not copy provider correspondence/account details or add links or references to private evidence.

## 5. Walk through abuse handling

Ask a maintainer unfamiliar with current response practices to use the runbook to handle a hypothetical notice from intake through triage, response, and the decision to contact the provider. Time the walkthrough and record whether the maintainer can identify the intake route, next action, and escalation decision within 10 minutes. Confirm the runbook identifies response steps, the minimum operational record, and follow-up owner/action; sets no abuse response-time target; and does not ask operators to collect user traffic or destination details. The 10-minute limit measures runbook usability, not the response time promised to a complainant.

## Completion checks

- All seven ports have a purpose, policy decision, transport-aware check method, dated result, and any required follow-up.
- DNS and the OpenVPN-labelled entry are assessed according to their actual protocol rather than port number alone.
- Public identity checks have dated, shareable results or explicit unsupported/unavailable status.
- Dedicated-host, provider-permission, and provider-support statuses, check dates, and non-sensitive follow-ups are recorded without private evidence or references.
- A reviewer can follow the abuse response and provider escalation process without undocumented operator knowledge.
- No active Tor policy or node configuration was changed during these checks.
