#!/bin/bash
ansible-playbook -i cluster shutdown-all.yml --ask-become-pass
