#! /bin/bash
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/install-python/install-python.yml
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/install-dependencies/install-dependencies.yml
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/setup-services/setup-services.yml
