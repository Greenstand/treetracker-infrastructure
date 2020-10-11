### Getting logged into the cluster

See the [monitoring readme](../monitoring/README.md) for info on how to auth to the k8s clusters

### What is ambassador?

An API gateway to allow you to wire up various services

It has some interesting setup that we followed from [here](https://www.getambassador.io/docs/latest/topics/install/helm/)

It also provides an edgectl CLI for setting up TLS termination, shown [here](https://github.com/datawire/ambassador-docs/blob/master/user-guide/getting-started.md)

The playbooks within here require helm to run.

Once you have the playbook run in the cluster, you can run `edgectl install` and follow the on screen prompts.

`dev` -> `edgectl login elated-shannon-1206.edgestack.me`
