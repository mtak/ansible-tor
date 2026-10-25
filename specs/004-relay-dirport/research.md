# Relay DirPort investigation

Date: 2026-10-25

## Decision

Remove `DirPort 80` from both relay configurations and remove the matching inbound
TCP/80 firewall rule. Keep `DirCache 1` and `ORPort 443`. Tor clients access
directory caches over the relay ORPort by default; publishing a separate
directory port provides no identified operational need for these relays.

The configured DirPort front page is an exit notice served specifically by the
DirPort. Because the project has no other web server or HTTP service configured
on the relays, keeping the notice would require retaining a deprecated listener
or adding a separate service. The current configuration provides no evidence
that this notice is relied on, so this change removes it along with DirPort.

## Evidence

- The current Tor manual says `DirPort` defaults to `0`, is not required for
  `DirCache`, clients connect via `ORPort` by default, and clients do not use
  relay DirPorts; it says it is safe to remove `DirPort` from `torrc`:
  <https://manpages.debian.org/testing/tor/tor.1.en.html>
- The Tor Project exit relay guide documents `DirPortFrontPage` as a way to
  display an exit notice on TCP/80, and explicitly says DirPort is deprecated
  since Tor 0.4.6.5:
  <https://community.torproject.org/relay/setup/exit/>
- In this repository, both relay templates set `DirPort 80` and
  `DirCache 1`; the shared iptables template accepts inbound TCP/80. There is
  no separate web server role or other HTTP listener configured.

## Scope and validation boundary

This decision is based on current Tor documentation and repository
configuration. The deployed Tor version and live traffic on TCP/80 were not
available for this investigation. Tor release notes state that since 0.4.6.1,
non-authoritative relays do not publish DirPort but still listen on it; this
does not create a continuing directory-service need. Deployment should be
followed by confirming that Tor restarts successfully and TCP/80 is closed.
