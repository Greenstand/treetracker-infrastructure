This playbook and associated role(s) is used to set up Linux virtual servers to act as a Docker Swarm cluster for the use of treetracker container deployments. 

The `hosts` file contains three manager nodes by IP address. 

The Docker swarm cluster and its component nodes were set up by hand during the late March 2019 SF Infrastructure code jam; it will be the goal of this bit of ansible code to be able to recreate this cluster and perform cluster management operations on it in a repeatable, automated manner.

In order to pass the health check for the load balancer, we have to set the LB to http, port 80, and the check to be `/health`

## Rudimentary setup steps

to make one from scratch, you'll have to add an LB in DO, however many nodes (though 2+ is probably best)
then add their hosts to the inventory file, and swap the `swarm` and `swarm_single` groups to your new group
then add the domain for the LB, and the domain in the hosts
and then there are two playbooks, `create-swarm.yml` and `deploy-all-playbook.yml`
running those 2 in order should get everything going
I have a wrapper script for the second, `build_and_deploy.sh`
and the last bit I don't like is the config files have to be copied in
