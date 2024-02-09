#!/bin/bash

docker run \
  --rm -ti \
  --user `id -u` \
  -v `pwd`:/home/mtak/ansible \
  -v $HOME/.ssh:/home/mtak/.ssh \
  -v $SSH_AUTH_SOCK:/home/mtak/ssh-agent \
  -e 'SSH_AUTH_SOCK=/home/mtak/ssh-agent' \
  --workdir=/home/mtak/ansible \
  merijntjetak/ansible:1.0 ansible-playbook $@

