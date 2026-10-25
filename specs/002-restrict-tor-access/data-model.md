# Data Model: Tor Access Policy

This feature introduces no application records or persistent business data. The following are configuration concepts used to express and verify the policy.

## Control Access Policy

- **Purpose**: Defines which local clients may use the Tor control interface and how they authenticate.
- **Attributes**: Local listener address/socket; authentication requirement; authorized local clients (the `debian-tor` exporter and root-operated Nyx).
- **Rules**: No remote client can connect. Requests without valid authentication are rejected. Both authorized clients retain their required functions.

## Metrics Scraper Source

- **Purpose**: Identifies a network source permitted to retrieve native Tor metrics.
- **Attributes**: Address family; source address or prefix; association with the Prometheus scraper.
- **Rules**: Only confirmed scraper sources are admitted by the Tor metrics policy and network firewall. Address values must agree across both controls and the operational documentation.

## Metrics Access Policy

- **Purpose**: Defines the listener and source rules for native Tor metrics.
- **Attributes**: Listener address/interface; port; accepted scraper source set; corresponding firewall rule.
- **Rules**: Sources outside the authorized scraper set are denied. The exporter HTTP endpoint remains a separate service path and does not substitute for testing the native metrics listener.
