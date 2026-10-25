# Quickstart: Validate Unbound Resolver Security and Exit DNS Monitoring

## Prerequisites

- Ansible controller access and credentials for the active managed nodes.
- `unbound-checkconf`, `unbound-control`, `dig`, `ss`, and `ip` available on target nodes.
- Access to the existing Prometheus service and its rule validation/test tooling.
- An approved DNSSEC-valid test name and a controlled DNSSEC-invalid test fixture. Avoid using arbitrary user query data for validation.

## 1. Validate Ansible configuration

From the repository root:

```sh
ansible-playbook --syntax-check playbook.yml
ansible-playbook --check --diff --limit all-servers playbook.yml
```

Expected: syntax validation succeeds and check mode shows only the intended resolver/exporter changes for the current inventory. The active exit target is `tor03`; resolver posture applies to all active `all-servers` hosts.

## 2. Apply and inspect resolver state

Apply the playbook to the intended targets using the normal operational change process. On each managed node, inspect the merged resolver configuration and running listeners:

```sh
sudo unbound-checkconf
sudo unbound-control status
sudo ss -luntp '( sport = :53 )'
```

Expected: Unbound is healthy and accepts recursive DNS only on enabled loopback addresses. No public or private network address is listening for recursive service. Confirm the effective access-control rules allow loopback only.

From the node, run positive and negative validation checks:

```sh
dig @127.0.0.1 <approved-valid-test-name> A +dnssec
```

Expected: the valid test resolves and includes DNSSEC validation evidence where applicable. Query the controlled DNSSEC-invalid fixture and expect it to fail validation. From a separate host, query the node's non-loopback address and expect no recursive answer.

## 3. Verify outbound source selection and package currency

Use a representative authoritative destination selected for the test and inspect the operating system's route decision:

```sh
ip route get <authoritative-dns-address>
```

Compare the selected source address with the source used by a controlled outbound DNS exchange. Expected: Unbound does not pin a source address, and the observed source matches the operating system's current route decision. Repeat after any route/address-family changes relevant to the node.

Compare the installed Unbound package with the latest version in the node's configured supported repositories. A repository access failure must be reported as unverified, not current.

## 4. Verify aggregate metrics and alerts

On each target, check the Unbound exporter endpoint and expected aggregate series:

```sh
curl -fsS http://127.0.0.1:9167/metrics | rg '^(unbound_up|unbound_answer_rcodes_total|unbound_request_list_exceeded_total)'
```

Expected: `unbound_up` indicates successful collection and the SERVFAIL counter is available. No series or labels contain query names or client identities.

Import the canonical rule file into the existing external Prometheus service and validate it with that service's rule checker. Confirm the configured expected-node labels map to the active exit target. Use rule tests or a controlled metric fixture to verify:

- A sustained SERVFAIL rate above the configured threshold remains pending for more than one hour, then fires on the next evaluation.
- The first healthy evaluation resolves the alert.
- Missing or unavailable exporter telemetry fires a monitoring-failure alert.
- The alert identifies the exit node and resolver failure signal, and does not describe SERVFAIL as a proven upstream timeout.

The external Prometheus service's alert receiver must remain its existing configured notification path.
