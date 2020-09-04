#!/usr/bin/env bash

HOSTNAME=$1
: "${HOSTNAME:?Hostname not set or empty}"

. ./arch-env.sh

ssh-copy-id -i ~/.ssh/id_ed25519 "$USER_NAME"@"$HOSTNAME"
ssh "$USER_NAME"@"$HOSTNAME" mkdir laptop-setup
./rsync-all.sh $HOSTNAME
ssh "$USER_NAME"@"$HOSTNAME" 'cd laptop-setup/ansible && ./run-ansible.sh'
