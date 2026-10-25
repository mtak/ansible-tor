# Research: Unbound Resolver Security and Exit DNS Monitoring

## Repository Findings

- `roles/unbound/tasks/main.yml` installs the latest Unbound package, points `/etc/resolv.conf` at `127.0.0.1`, enables remote control and extended statistics, and conditionally disables IPv6. It does not explicitly define DNS listener interfaces, client access rules, DNSSEC validation, or QNAME minimization.
- `roles/prometheus-exporters/tasks/unbound-exporter.yml` installs the Unbound exporter v0.4.1 and configures its local TLS control connection. The exporter exposes Unbound aggregate statistics.
- `roles/prometheus-exporters/tasks/tor-exporter.yml` installs atx `prometheus-tor_exporter` v0.4. Its metrics include relay reachability, state, throughput, uptime, flags, and accounting, but no DNS timeout or DNS error metrics.
- `README.md` says Prometheus is generally used for day-to-day monitoring. The repository contains no Prometheus scrape configuration, alert rules, Alertmanager configuration, or notification routing. The active inventory has three managed nodes, including one active Tor exit node (`tor03`).
- The firewall template allows scrape ports from configured control networks, while loopback access is separately allowed. Loopback-only Unbound listeners are therefore the primary resolver boundary; this feature does not need a new firewall service or monitoring component.

## Decisions

### Resolver listeners and client boundary

**Decision**: Explicitly configure and verify loopback-only recursive service. Use the IPv4 loopback address and, when IPv6 is enabled for a node, IPv6 loopback. Explicitly permit the loopback client ranges and refuse other clients.

**Rationale**: The clarified requirement allows requests from the node itself only. `/etc/resolv.conf` points to IPv4 loopback, but that alone does not establish effective Unbound listeners or access controls. Explicit role-managed settings make the intended boundary reproducible and auditable.

**Alternatives considered**: Rely on packaged defaults; rejected because merged configuration can change effective behavior. Bind all interfaces and rely on firewall rules; rejected because the node firewall accepts UDP broadly and the resolver should enforce its own narrow service boundary.

**Reference**: [Unbound configuration manual: server options](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html#server-options).

### DNSSEC and QNAME minimization

**Decision**: Explicitly verify DNSSEC validation, a usable trust anchor, and non-permissive validation. Explicitly enable best-effort QNAME minimization; do not enable strict minimization.

**Rationale**: The official manual documents validator behavior and trust-anchor requirements. QNAME minimization is enabled by default and may fall back for compatibility. Strict mode can make domains unresolvable and is not needed to meet the user requirement.

**Alternatives considered**: Rely on defaults; rejected for an auditable security posture. Strict QNAME minimization; rejected because it can reduce compatibility without being required by the spec.

**References**: [Unbound configuration manual: module configuration and trust anchors](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html#module-config), [QNAME minimization](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html#qname-minimisation).

### Outbound resolver source address

**Decision**: Leave Unbound's outbound-interface binding unset so the operating system selects the source address using its routing state; verify the selected source address on each target node.

**Rationale**: This matches the user's choice and avoids pinning host-specific addresses in shared configuration. A runtime route check is still required because the current repository does not document the actual egress address for DNS traffic.

**Alternative considered**: Configure a fixed address per node; rejected by the user.

**Reference**: [Unbound configuration manual: outgoing-interface](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html#outgoing-interface).

### DNS failure signal and alert behavior

**Decision**: Use per-node aggregate Unbound statistics. Use the current exporter's `unbound_answer_rcodes_total{rcode="SERVFAIL"}` as the broad resolver-failure signal and `unbound_up` / scrape availability to detect missing telemetry. Alert after the configured SERVFAIL threshold remains exceeded for more than one hour. Resolve on the first healthy evaluation. Deliver through the existing Prometheus-based monitoring service; do not add a new monitoring service.

**Rationale**: The pinned Tor exporter v0.4 does not export DNS timeout/error metrics. The pinned Unbound exporter v0.4.1 maps `num.answer.rcode.<CODE>` to `unbound_answer_rcodes_total{rcode="<CODE>"}`. Upstream timeouts can lead to SERVFAIL, but SERVFAIL can also result from DNSSEC or other resolution failures; the alert must identify a resolver failure signal without claiming a specific cause. The exporter does not map Unbound's `num.queries_timed_out`. Unbound documents that counter as queries dropped after waiting too long in the UDP socket buffer, which is an ingress queue timeout rather than an upstream DNS timeout. Do not treat it as evidence of upstream timeout.

Prometheus supports a `for` duration to delay firing and resolves an alert at the first evaluation where the expression is no longer true unless a firing-retention period is configured. Omit that retention setting to match the clarified immediate recovery behavior.

**Alternatives considered**: Use Tor exporter metrics for DNS; rejected because the pinned exporter has none. Label SERVFAIL as an upstream timeout; rejected because its cause is not specific. Parse per-query logs; rejected because it would risk collecting query-level information and conflicts with the constitution. Add a separate monitoring component; rejected because the spec selects the existing monitoring service and the constitution requires a stated need for new components.

**References**: [atx Tor exporter v0.4 collector](https://raw.githubusercontent.com/atx/prometheus-tor_exporter/v0.4/prometheus-tor-exporter.py), [Let's Encrypt Unbound exporter v0.4.1 source](https://github.com/letsencrypt/unbound_exporter/blob/v0.4.1/unbound_exporter.go), [Unbound control statistics](https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound-control.html), [Prometheus alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/), [Prometheus alerting overview](https://prometheus.io/docs/alerting/latest/overview/).

### External alert-rule integration

**Decision**: Keep a Prometheus rule file in this repository as the canonical, reviewable rule definition, under `monitoring/prometheus/`. The rule must be imported by the existing external Prometheus service; the external notification receiver remains owned by that service's current configuration.

**Rationale**: The repository manages node exporters but not the Prometheus server or its receivers. A version-controlled rule fragment keeps the alert reproducible without pretending this Ansible repository deploys or owns the external monitoring server.

**Alternatives considered**: Add a Prometheus/Alertmanager server to this repository; rejected as unrelated new infrastructure. Keep rules only in an undocumented external UI; rejected because it would not satisfy repository-managed reproducibility.

**Integration dependency**: During implementation, confirm the external Prometheus rule import path and its stable per-node target label with the monitoring owner. The rule artifact and its contract can be prepared independently.

## Deferred Operational Values

- Choose the numeric SERVFAIL threshold using the existing Prometheus series and an observed baseline; the specification intentionally makes it configurable.
- Confirm the external Prometheus rule import path, target label, and existing notification route at implementation time. No server-side scrape or receiver configuration exists in this repository.
