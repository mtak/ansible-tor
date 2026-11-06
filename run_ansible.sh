#!/usr/bin/env bash

set -euo pipefail

docker_args=(
  --rm -ti
  --user "$(id -u)"
  -v "$PWD:/home/mtak/ansible"
  -v "$HOME/.ssh:/home/mtak/.ssh"
  --workdir=/home/mtak/ansible
)

if [[ -n ${SSH_AUTH_SOCK:-} ]]; then
  docker_args+=(
    -v "$SSH_AUTH_SOCK:/home/mtak/ssh-agent"
    -e SSH_AUTH_SOCK=/home/mtak/ssh-agent
  )
fi

if [[ -n ${TOR_FAMILY_KEY_FILE:-} ]]; then
  if [[ $TOR_FAMILY_KEY_FILE != /* || ! -f $TOR_FAMILY_KEY_FILE || ! -r $TOR_FAMILY_KEY_FILE ]]; then
    echo "TOR_FAMILY_KEY_FILE must name a readable absolute family key file." >&2
    exit 1
  fi
  docker_args+=(
    -v "$TOR_FAMILY_KEY_FILE:/run/secrets/taktor-family-key:ro"
    -e TOR_FAMILY_KEY_FILE=/run/secrets/taktor-family-key
  )
fi

docker run "${docker_args[@]}" merijntjetak/ansible:1.0 ansible-playbook "$@"

