## What is this?

A simple script to list out the contents of each cluster

## How does it work?

1. Get access to a cluster through doctl/ kubectl (e.g. `./scripts/doctl_setup.sh dev-k8s-treetracker`)
2. Run this script to dump the deployments and various metadata about them `python3 list_tags_for_deployments.py`
