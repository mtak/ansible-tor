# Relay DirPort investigation

Date: 2026-10-25

## Decision

Keep `DirPort 80` and `DirPortFrontPage` on both relay types, and keep inbound
TCP/80 open in the shared firewall. The operator wants to maintain the relay
and exit notice pages. Tor's built-in front-page feature serves these pages
without adding a separate HTTP daemon, keeping the attack surface smaller than
installing another network service.

`DirPort` is deprecated for directory service and Tor clients access directory
caches over `ORPort` by default. Its continued use here is limited to the
documented HTTP notice page. Keep `DirCache 1` and `ORPort 443` as before.

An alternative daemon was considered and rejected: Ubuntu's security tracker
marks `micro-httpd` vulnerable to CVE-2014-4927, a remotely triggerable buffer
overflow, including in supported Ubuntu releases. It is not an appropriate
replacement for an internet-facing listener.

## Evidence

- The current Tor manual says `DirPort` defaults to `0`, is not required for
  `DirCache`, clients connect via `ORPort` by default, and clients do not use
  relay DirPorts; it says it is safe to remove `DirPort` from `torrc`:
  <https://manpages.debian.org/testing/tor/tor.1.en.html>
- The Tor Project exit relay guide documents `DirPortFrontPage` as a way to
  display an exit notice on TCP/80, and explicitly says DirPort is deprecated
  since Tor 0.4.6.5:
  <https://community.torproject.org/relay/setup/exit/>
- Ubuntu's security tracker marks `micro-httpd` vulnerable to CVE-2014-4927:
  <https://ubuntu.com/security/CVE-2014-4927>
- In this repository, both relay templates set `DirPort 80` and
  `DirCache 1`; the shared iptables template accepts inbound TCP/80. There is
  no separate web server role or other HTTP listener configured.

## Scope and validation boundary

This decision is based on current Tor documentation and repository
configuration. The deployed Tor version and live listener state were not
available for this investigation. Tor's current exit guide still documents
DirPortFrontPage for exit notices while noting DirPort deprecation. Deployment
should confirm Tor restarts successfully and that the notice is served on
TCP/80 for both relay types.
