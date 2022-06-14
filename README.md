# treetracker-infrastructure

Cloud infrastructure for the treetracker project

# ADRs
ADRs for infrastructure are located at https://github.com/Greenstand/treetracker-infrastructure-adr



# Pre-commit Github Action

We use pre-commit in a GitHub Action to format the terraform files for best practices. To make the workflow even easier, you can run those checks on your own machine before pushing code.

Installing pre-commit

Reference:
https://pre-commit.com/

Then run from the root folder of the repo:
```sh
pre-commit install
pre-commit run --all-files
```
