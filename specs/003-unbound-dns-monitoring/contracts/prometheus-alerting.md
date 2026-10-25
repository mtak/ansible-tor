# Prometheus Alerting Contract

## Scope

The repository provides node-side Unbound statistics and a canonical rule file for import into the existing external Prometheus service. It does not deploy Prometheus, configure its scrape targets, or configure its notification receiver.

## Input Series

- `unbound_answer_rcodes_total{rcode="SERVFAIL"}`: aggregate Unbound SERVFAIL answer counter from the existing Unbound exporter.
- `unbound_up`: exporter successfully collected Unbound control statistics.
- Prometheus target scrape status for each expected exit node: used to detect missing exporter telemetry.
- `unbound_request_list_exceeded_total{thread}`: optional supporting signal for resolver saturation diagnosis; not a substitute for the SERVFAIL alert.

The alert definition must use stable per-node target labels supplied by the external scrape configuration. The implementation must verify the actual label name/value before composing the final expression. It must not add labels for DNS names, client addresses, or individual queries.

## Deployment Inputs to Confirm

This repository has no Prometheus scrape configuration or monitoring-owner contact details. The active exit inventory host is `tor03.mtak.nl`. The rule bundle currently assumes the external scrape target uses `instance="tor03.mtak.nl:9167"` (the Unbound exporter default endpoint); the monitoring owner must confirm or replace this selector before importing the rules. The external rule-import path and notification receiver are also outside this repository and remain operator-owned. No recent SERVFAIL series or baseline is available in this checkout, so the initial threshold in the rule bundle is provisional and must be reviewed against the service's observed data before production use.

## Alert Behavior

1. Fire a per-node resolver-failure alert when the configured SERVFAIL threshold remains exceeded continuously for more than one hour. In Prometheus terms, use an alert pending duration of one hour and allow the next rule evaluation to transition it to firing.
2. Clear the alert on the first evaluation where the signal returns to its healthy range. Do not configure an additional firing-retention period.
3. Fire a separate monitoring-failure alert when the exporter cannot collect statistics or an expected exit-node target is missing. Missing telemetry is not a healthy resolver result.
4. Attach the node identity, signal name, observed rate/count, configured threshold, and investigation guidance. Use the external service's existing severity and receiver conventions.
5. Describe SERVFAIL as a resolver failure signal. Do not claim that it proves an upstream timeout; DNSSEC and other resolver failures can also produce SERVFAIL.

## Validation Contract

- The rule bundle passes the external Prometheus rule syntax checker.
- A rule test with a sustained over-threshold SERVFAIL series fires after the configured one-hour pending period and no earlier than the next evaluation.
- A healthy next evaluation resolves a firing alert.
- An unavailable exporter or missing expected exit target produces a monitoring-failure alert.
- Alert labels identify the expected exit node and contain no query-level or user-specific data.
