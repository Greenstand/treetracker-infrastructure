#!/bin/bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible
sudo apt-get install python3-pip
pip3 install docker
