#!/usr/bin/env bash

TARGET=$1
: "${TARGET:?Target not set or empty}"

ssh-copy-id -i ~/.ssh/id_ed25519 root@"$TARGET":
scp scripts/arch-setup* arch-env.sh root@"$TARGET":

ssh root@"$TARGET" 'source arch-env.sh && ./arch-setup.sh'
