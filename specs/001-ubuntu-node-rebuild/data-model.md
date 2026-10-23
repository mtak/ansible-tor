# Data Model: Ubuntu Node Rebuild

This feature configures existing infrastructure records; it introduces no persistent application database or new external API.

## Node

| Field | Source | Validation |
|---|---|---|
| Inventory hostname | `inventory` | Must identify exactly one active host. |
| Node class | `tor-relay` or `tor-exit` inventory group | `tor01` and `tor02` are relays; `tor03` is an exit. |
| OS release | Provider image upgrade and `/etc/os-release` | Final release must be Ubuntu 26.04 LTS (Resolute) before Ansible configuration runs. |
| Public address | Provider assignment and DNS | Confirm before rebuild; update DNS and relevant configuration if it changes. |
| Host settings | `host_vars/<hostname>` | Preserve node-specific location, IPv6, bandwidth, and relay settings. |
| Expected Tor fingerprint | `host_vars/<hostname>` | Restored routine-recovery identity must match exactly. |
| Provisioning state | Ansible connectivity, role run, and service checks | Track as not rebuilt, configured, or verified; do not mark the fleet recovered when any host fails. |

## Tor Identity Backup

| Field | Source | Validation |
|---|---|---|
| Node association | Inventory hostname in encrypted backup path/name | Must map unambiguously to one active host. |
| Key set | Complete `/var/lib/tor/keys` directory | Encrypted at rest and restored only for routine recovery. |
| Decryption recipient | Existing SSH public-key recipient or a newly established recovery recipient | A working private identity must be available as a protected file to the `age` CLI. |
| Identity fingerprint | Host variable and Tor's restored identity | Must match before the disk-erasing provider action. |
| Compromise status | Operator recovery decision | If suspected, use new keys and never restore that node's old identity. |

## Service Role

A repository-owned responsibility implemented by an existing Ansible role. Shared host setup and service configuration remain with the current owners in `roles/base`, `roles/ssh`, `roles/iptables`, `roles/haveged`, `roles/unbound`, `roles/tor`, `roles/tor-relay`, `roles/tor-exit`, `roles/prometheus-exporters`, and `roles/report`.
