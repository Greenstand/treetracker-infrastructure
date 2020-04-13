#!/bin/bash

sudo apt-get update
sudo apt-get install virtualbox -y
curl -O https://releases.hashicorp.com/vagrant/2.2.6/vagrant_2.2.6_x86_64.deb
sudo apt install ./vagrant_2.2.6_x86_64.deb
rm ./vagrant_2.2.6_x86_64.deb
vagrant plugin install vagrant-disksize