#!/bin/bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install libffi-dev libssl-dev software-properties-common --yes
sudo apt-get install node-gyp npm --yes
sudo apt-get install python3-dev python3-pip python3-docker --yes
pip3 install ansible docker --upgrade
