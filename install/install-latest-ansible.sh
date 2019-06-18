#!/bin/bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install libffi-dev libssl-dev software-properties-common python3-docker --yes
sudo apt-get install python3-dev python3-pip --yes
pip3 install ansible docker --upgrade
