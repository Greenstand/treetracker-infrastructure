#!/bin/bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install software-properties-common --yes
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install python3-pip --yes
pip3 install ansible docker --upgrade
