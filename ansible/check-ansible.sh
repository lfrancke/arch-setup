#! /usr/bin/env bash

ansible-playbook --check -i inventory/local --vault-password-file vault-pass main.yml
