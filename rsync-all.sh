#!/usr/bin/env bash

. ./arch-env.sh

rsync -axv --delete --progress --stats --exclude '.DS_Store' -e "ssh -T -o Compression=no -x"  ./ lars@"$1":/home/lars/laptop-setup
