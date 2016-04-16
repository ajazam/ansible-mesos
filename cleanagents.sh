#!/bin/bash
ansible-playbook -i cluster cleanagents.yml --ask-become-pass
