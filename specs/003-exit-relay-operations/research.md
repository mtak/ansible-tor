# Research: Exit Relay Operations and Policy Review

## Decision: Review every configured destination port with an explicit purpose and transport

**Rationale**: The current configuration lists ports 53, 80, 443, 993, 995, 1194, and 11371, with comments identifying DNS, HTTP, HTTPS, IMAPS, POP3S, OpenVPN, and OpenPGP HKP. Tor's exit guide explains that an exit policy controls destination ports and trades off abuse exposure against relay usefulness. Tor's stream specification describes opening a TCP connection to the destination; its SOCKS extensions explicitly do not support UDP ASSOCIATE. Reachability checks must therefore name the transport and destination, and an OpenVPN service that requires UDP must not be recorded as reachable through the standard Tor exit stream path.

**Alternatives considered**:
- Treat each port number as sufficient evidence of intended service: rejected because ports can carry different protocols and reachability depends on transport.
- Treat any host-level UDP reachability as proof that a Tor client can use that port: rejected because standard Tor exit streams use TCP and SOCKS UDP ASSOCIATE is unsupported.

**Sources**:
- [Tor Project: Exit Relay](https://community.torproject.org/relay/setup/exit/)
- [Tor Specifications: Opening streams and transmitting data](https://spec.torproject.org/tor-spec/opening-streams.html)
- [Tor Specifications: SOCKS extensions](https://spec.torproject.org/socks-extensions)
- Repository source: `group_vars/all/tor`, `roles/tor-exit/templates/torrc`

## Decision: Keep policy changes separate from this review

**Rationale**: The feature clarification requires documenting findings and recommendations for separate explicit approval and rollout. Tor guidance says the operator chooses which services to allow, recommends at least ports 80 and 443 for a useful exit, and suggests a reduced policy when starting with a new hoster. Those recommendations inform review; they do not justify changing tor03's active policy without an operator decision.

**Alternatives considered**:
- Automatically remove any port that fails a check: rejected because it would change live service behavior and could be a false result caused by a remote endpoint or check location.
- Treat existing ports as already justified: rejected because the issue explicitly asks for a rationale and verification for each port.

**Sources**:
- [Tor Project: Exit Relay](https://community.torproject.org/relay/setup/exit/)
- [Tor Support: Exit relay abuse and exit policies](https://support.torproject.org/relays/legal-and-abuse/exit-relay-abuse/)

## Decision: Document abuse handling without adding a response-time target

**Rationale**: Tor community resources recommend timely responses and describe 24 hours as usual guidance. The accepted clarification excludes a response-time target from this feature, so the procedure will specify intake, triage, response steps, recordkeeping, and provider escalation without creating an SLA. This is a feature-scope decision, not a claim that Tor's timing guidance is irrelevant.

**Alternatives considered**:
- Add a 24-hour deadline based on Tor community guidance: rejected for this feature because the user selected no response-time target.
- Omit handling steps and rely on general Tor advice: rejected because issue #7 requires an actionable local process and provider escalation route.

**Sources**:
- [Tor Project: Community and legal resources](https://community.torproject.org/relay/community-resources/)
- [Tor Support: Exit relay abuse and exit policies](https://support.torproject.org/relays/legal-and-abuse/exit-relay-abuse/)

## Decision: Check public identity records and record provider readiness with minimal non-sensitive metadata

**Rationale**: Tor Project guidance recommends recognizable reverse DNS for an exit and suitable operator contact/registration information where supported. The feature requires checking reverse DNS and applicable WHOIS or equivalent records. Provider dedication and permission cannot be inferred from public Tor guidance or the repository's provider name; they require checking the operator's account or terms. The accepted clarification excludes private evidence details and references from repository documentation. The repository may record each provider readiness status, its check date, and a non-sensitive follow-up.

**Alternatives considered**:
- Infer provider support from the fact that tor03 is configured as an exit: rejected because configuration does not prove current provider terms or support.
- Store private provider correspondence or link to it in the repository: rejected by the accepted privacy boundary.
- Treat unsupported public record types as failures: rejected because the spec allows unsupported or unavailable status with a follow-up when appropriate.

**Sources**:
- [Tor Project: Exit Relay](https://community.torproject.org/relay/setup/exit/)
- [EFF Tor Legal FAQ for Relay Operators](https://community.torproject.org/relay/community-resources/eff-tor-legal-faq/)
- Repository source: `host_vars/tor03.mtak.nl` (provider context only; not evidence of permission or dedication)

## Decisions deferred to operator evidence gathering

- Whether each of the seven existing ports is intentionally allowed and reachable from the relay under the applicable TCP service.
- Whether port 1194 is intended for TCP OpenVPN or for UDP OpenVPN; only the former can be tested as a standard Tor exit stream.
- Whether provider terms support an exit relay on a dedicated host and whether the current public identity records meet operator goals.
- Whether any proposed change to the current policy should be approved and rolled out.

The plan does not claim that provider checks or network reachability checks have already been performed.
