#! /bin/bash
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/update-pipeline/update-pipeline-microservice.yml
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/update-pipeline/update-pipeline-consumer.yml
ansible-playbook  -i ../hosts/dev.hosts -l batch --user root  playbooks/update-pipeline/update-pipeline-cron.yml
