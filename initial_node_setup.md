# Initial node setup

TakTor is designed to be used on cheap VPS'es. This document outlines a
step-by-step plan to get a new Debian 10 VPS to a state where it can be used
with Ansible.

## Steps

```shell
passwd

useradd -m -d /home/mtak -s /bin/bash mtak
su - mtak
mkdir .ssh
cat <<EOF >.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGL0j1h7tTvBh1VQHCiy/XRLjHXaZh0Hpl/gdoM44/lO mtak
EOF
exit

apt-get update
apt-get install -y sudo

cat <<EOF >>/etc/sudoers
mtak	ALL=(ALL) NOPASSWD: ALL
EOF
```
