# Quickstart: Validate Tor FamilyID

This guide describes validation after the feature is implemented. It does not create a family key or change a live relay during planning. See [operator-inputs.md](contracts/operator-inputs.md) for the input contract and [data-model.md](data-model.md) for verification states.

## Prerequisites

- A decoded, byte-for-byte `.secret_family_key` file outside this repository, readable by the deploying account. The password manager stores the same secret as base64 text; base64 is not encryption.
- The public FamilyID generated with that key and its SHA-256 digest recorded in shared Tor variables.
- A supported Debian or Ubuntu LTS host and compatible remote Python/Ansible environment before a live playbook run. The [runbook](../../ANSIBLE_RUNBOOK.md) records that the current Debian 10/Python 3.7.3 baseline cannot run normal modules from ansible-core 2.21.4.
- `curl` and `jq` for the external publication check. Public data may take time to update after a relay publishes a new descriptor.

## 1. Validate controller input and syntax

From the repository root, set the path to the existing decoded binary file. An external `.env` may contain only this assignment; keep both binary key bytes and their base64 representation out of it. Compute SHA-256 over the binary file, not the base64 text.

```sh
export TOR_FAMILY_KEY_FILE="$HOME/.local/share/taktor/family.secret_family_key"
test -r "$TOR_FAMILY_KEY_FILE"
sha256sum "$TOR_FAMILY_KEY_FILE"
ANSIBLE_LOCAL_TEMP=/tmp ansible -i inventory all-servers --list-hosts
ANSIBLE_LOCAL_TEMP=/tmp ansible-playbook -i inventory playbook.yml --syntax-check
```

Compare the printed digest with the expected public digest in shared Tor variables. The feature's preflight performs that comparison again and stops on a mismatch. The inventory should contain tor01, tor02, and tor03 today. No command above prints the key bytes or changes a relay.

## 2. Check target readiness and apply

First follow the runbook's connectivity and supported-platform checks. Do not treat a successful `raw` SSH check as proof that Ansible modules will run. On a compatible baseline, run the family deployment with the existing wrapper, which will mount the local key read-only after this feature is implemented:

```sh
./run_ansible.sh -i inventory playbook.yml --tags tor
```

Expected: controller preflight passes; each target supports `FamilyId`; the same family key is installed before either `torrc` template activates the public ID; no key bytes or diffs appear in output. A failure leaves the rollout incomplete. The project constitution permits applying to all targeted nodes together.

## 3. Check public family publication

Use the three current fingerprints from `host_vars` and substitute the public ID from shared Tor variables. Onionoo returns the bare ID in `family_ids`; Tor microdescriptors use the `ed25519:` prefix. Compare Onionoo values against the bare public ID. For each relay, inspect the exact fingerprint, `last_seen`, `family_cert`, and `family_ids` fields:

```sh
expected_family_id='<PUBLIC_FAMILY_ID>'
for fingerprint in \
  8696DC7AC0470F6ED5C7AC48030002D7D3716FC9 \
  69042D0DC33BD810BD08ADADBC7E95A3CABAEF64 \
  1D65771E68383F294D4F1131B19DF64989EEDF8A
do
  curl --fail --silent --show-error \
    "https://onionoo.torproject.org/details?search=$fingerprint" |
    jq --arg fingerprint "$fingerprint" --arg expected "$expected_family_id" \
      '.relays[] | select(.fingerprint == $fingerprint) | {fingerprint, last_seen, has_family_cert: (.family_cert != null), has_expected_family_id: ((.family_ids // []) | index($expected) != null)}'
done
```

Mark a relay **verified** only when its fresh record has both booleans true. A missing or stale record is **pending**; a fresh record missing either value is **failed**. Recheck pending publication after directory propagation. All active relays must be verified before closing issues #8 and #18. For future relays, use their new fingerprints rather than extending a `MyFamily` list.

**Publication verified 2026-11-06 at 14:35 UTC:** Onionoo reported a 13:00 UTC consensus, after the 11:28–11:30 UTC deployment. Each exact fingerprint was running and last seen at 13:00 UTC, had a `family_cert`, and listed the configured bare FamilyID `ku5+Tm/sIKVcdQyUol12URn8Sk23Z5+5WJPVn6caRTY` in `family_ids`.

| Relay | Fingerprint | Status |
| --- | --- | --- |
| tor01 | `8696DC7AC0470F6ED5C7AC48030002D7D3716FC9` | Verified |
| tor02 | `69042D0DC33BD810BD08ADADBC7E95A3CABAEF64` | Verified |
| tor03 | `1D65771E68383F294D4F1131B19DF64989EEDF8A` | Verified |

## 4. Negative checks in a non-production environment

Set `TOR_FAMILY_KEY_FILE` to a missing file, then to a different file. In both cases, the preflight must stop before changing any relay family configuration and must not print the secret. Restore the intended path afterward. Check rendered relay and exit configuration for exactly one common `FamilyId` and no `MyFamily` line.

## 5. Check a future membership change without deploying

Make a temporary copy of `inventory` outside the repository. Add a
prospective hostname under `[tor-relay]` or `[tor-exit]`, then inspect the
result. This does not connect to the prospective host:

```sh
tmp_inventory=$(mktemp)
cp inventory "$tmp_inventory"
# Edit only "$tmp_inventory" to add the prospective active relay.
ANSIBLE_LOCAL_TEMP=/tmp ansible-inventory --playbook-dir "$PWD" \
  -i "$tmp_inventory" --graph
ANSIBLE_LOCAL_TEMP=/tmp ansible-inventory --playbook-dir "$PWD" \
  -i "$tmp_inventory" --host prospective.example
rm "$tmp_inventory"
```

The prospective host must appear in `all-servers` and inherit the shared
`tor_family_id`; the original active hosts keep the same value. Repeat with
one existing host removed from the temporary inventory and confirm it is no
longer in `all-servers`. The live `inventory` and family settings on
existing relays remain unchanged.
