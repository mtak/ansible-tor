# Research: Restrict Tor Control and Metrics Access

## Tor control listener and authentication

**Decision**: Keep the control interface on loopback and enable Tor cookie authentication. Preserve the local Tor exporter and Nyx as authorized clients; verify they use SAFECOOKIE challenge-response authentication.

**Rationale**: The exporter already connects to `127.0.0.1:9051` and its system service runs as `debian-tor`, the Tor daemon account. Its source calls Stem's controller `authenticate()` method, which supports SAFECOOKIE. Nyx is configured for the root operator and uses the Tor control protocol. Tor's cookie authentication provides a local authentication mechanism without exposing control remotely or placing a reusable password in the repository. Tor documents that the plain COOKIE method is deprecated; SAFECOOKIE proves access to the cookie with a challenge-response and is preferred. The torrc documentation cautions that an unauthenticated control port allows local processes to control Tor.

**Alternatives considered**: A remote ControlPort is rejected because no remote control is needed and it broadens exposure. A shared static control password is rejected because it would require secret distribution and storage when the intended clients are local.

**Sources**: [Tor torrc manual](https://manpages.debian.org/unstable/tor/torrc.5.en.html); [Tor control protocol implementation notes](https://spec.torproject.org/control-spec/implementation-notes.html); [Tor control protocol authentication](https://spec.torproject.org/control-spec/commands.html); [Nyx manual](https://manpages.debian.org/bookworm/nyx/nyx.1.en.html); [Tor exporter source](https://github.com/atx/prometheus-tor_exporter/blob/master/prometheus-tor-exporter.py).

## Native metrics listener and source policy

**Decision**: Restrict Tor's native metrics listener using an explicit policy for the Prometheus scraper source address(es), and ensure the network firewall admits the same intended sources. Bind the listener only to the interface/address needed for scraping.

**Rationale**: Tor's documentation describes `MetricsPortPolicy` as the source access policy for Prometheus and recommends allowing only the Prometheus server. Explicit source entries avoid the current `accept *` behavior. The repository already limits inbound port 9098 in iptables to `control_ipv4`/`control_ipv6`, but those variables also cover other operational access and are not identified as a scraper list. Therefore their relationship to the scraper must be confirmed before choosing final variable values.

**Alternatives considered**: Keeping `accept *` relies entirely on the host firewall and leaves Tor's own policy permissive. Reusing every generic control source as an allowlist without confirming scraper identity could grant metrics access to non-scraper administrators.

**Sources**: [Tor torrc manual](https://manpages.debian.org/unstable/tor/torrc.5.en.html).

## Existing repository integration points

- Both `roles/tor-relay/templates/torrc` and `roles/tor-exit/templates/torrc` currently set `MetricsPort {{ tor_metrics_port }} prometheus`, `MetricsPortPolicy accept *`, and `ControlPort 9051`; cookie authentication is commented out.
- `group_vars/all/tor` sets `tor_metrics_port` to 9098.
- `roles/iptables/templates/iptables` allows port 9098 only from `control_ip`; `roles/iptables/tasks/main.yml` renders it from `control_ipv4` and `control_ipv6`.
- `group_vars/all/external` provides those source lists, but no repository file maps individual entries to Prometheus scraping.
- The Tor exporter exposes its own HTTP endpoint on port 9099 and connects to Tor over loopback port 9051. Its systemd service runs as `debian-tor`.
- Nyx is installed/configured for root at `/root/.nyx/config` and is described as an operator recovery interface.

**Decision**: Treat Tor MetricsPort 9098 and exporter HTTP port 9099 as separate paths in implementation and validation. Preserve exporter and Nyx local control access while securing the native metrics port.
