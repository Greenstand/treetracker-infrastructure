This playbook and associated role(s) is used to set up Linux virtual servers to act as a Docker Swarm cluster for the use of treetracker container deployments. 

The `hosts` file contains three manager nodes by IP address. 

The Docker swarm cluster and its component nodes were set up by hand during the late March 2019 SF Infrastructure code jam; it will be the goal of this bit of ansible code to be able to recreate this cluster and perform cluster management operations on it in a repeatable, automated manner.

In order to pass the health check for the load balancer, we have to set the LB to port http, 80, and the check to be `/health`
