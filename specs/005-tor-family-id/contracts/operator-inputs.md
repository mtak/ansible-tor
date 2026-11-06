# Operator Input Contract: Tor FamilyID

This is the operator-facing deployment contract for the approved local-key workflow. It does not expose the family secret in the repository.

## Inputs

| Input | Location | Contract |
| --- | --- | --- |
| Family secret | `TOR_FAMILY_KEY_FILE` environment variable | Absolute path to the original Tor-generated binary `.secret_family_key` file on the controller. The file is outside Git and readable by the deploying account. An external `.env` file may set this path, but must not contain the secret bytes. |
| Public FamilyID | Shared Tor variable | Exact value generated with the same key; one value for all active relays. It is non-secret. |
| Expected key digest | Shared Tor variable | SHA-256 of the original secret file, pinned when the public ID is recorded. It is non-secret and rejects a substituted controller file. |
| Active members | `inventory` | Union of active relay and exit groups. Retired or commented hosts are excluded. |

## Execution behavior

1. Controller preflight rejects an unset, relative, missing, unreadable, or digest-mismatched key path before any relay family changes. Errors identify the input problem without showing secret bytes.
2. Native Ansible reads the local path directly. `run_ansible.sh` mounts that file read-only into Docker and passes its in-container path to Ansible. Docker receives no secret bytes through command arguments or environment variables.
3. The shared Tor role installs the same file on each active relay with Tor-service ownership and restricted permissions. Both relay types render the same explicit `FamilyId` and no `MyFamily`.
4. A missing Tor capability or failed key copy stops that target before its `torrc` family change. A partial or unverified rollout is reported as incomplete.

## Observable output

- Successful local validation reveals only path metadata, public ID, and checksum comparison status; it never prints key contents.
- A successful configuration run is not equivalent to verified publication. Every active fingerprint must later show a family certificate and expected family ID in fresh public network data.
- A failed or pending member is named by hostname or fingerprint, without exposing key material.
