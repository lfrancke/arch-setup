#! /usr/bin/env bash

ansible-playbook -i inventory/local --vault-password-file vault-pass main.yml
