# Data Model: One Tor Relay Family

## Active relay

An inventory host in the active `tor-relay` or `tor-exit` group. Today: tor01, tor02, tor03. Fields: inventory hostname, relay fingerprint, role (non-exit or exit), supported Tor capability, deployment state, and observed publication state. Decommissioned hosts are outside the active set.

**Validation**: Each targeted host supports `FamilyId`. Its expected public family identifier equals the common operator family identifier. No other active host's fingerprint is required in its family configuration.

## Operator family

The single family shared by all active relays. Fields: public FamilyID, expected secret SHA-256 digest, and current active member set derived from inventory. The public ID and digest are common to every member; the member set is not a serialized Tor fingerprint list.

**Validation**: Public ID is present and has Tor's expected syntax; digest is a 64-character hexadecimal SHA-256 value. One explicit family ID is used, rather than `FamilyId *`.

## Family secret

The private Tor-generated binary key. Fields: controller file path, expected digest, target key filename, target owner, and target access mode. The secret's content is never an inventory value or log field. The operator supplies a persistent local copy sourced from their password manager.

**Validation**: Before relay family changes, the controller file exists, is readable, and matches the expected digest. The copied key on a relay must be byte-for-byte identical and readable by Tor while inaccessible to ordinary users.

## Published membership

Public evidence for one active relay: relay fingerprint, observation time, presence of a family certificate, and advertised family ID set. Source is current network-visible descriptor data.

**State transitions**:

1. **Pending**: The relay is configured, but no fresh public evidence confirms its family relationship.
2. **Verified**: Fresh public data identifies the relay, includes its family certificate, and includes the expected family ID.
3. **Failed**: Fresh public data identifies the relay but lacks the expected certificate or family ID, or Tor reports a key-load error.

An offline relay remains pending. The migration is complete only when every active relay is verified.
