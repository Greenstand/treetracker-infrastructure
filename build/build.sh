#!/bin/bash
ansible-playbook build.yml -e "version="$1
