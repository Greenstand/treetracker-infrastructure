# Initialize the Kubernetes Terraform backend

Each environment has its own `backend.tf` with a complete DigitalOcean Spaces
backend configuration. Select the intended environment before initializing:

| Directory | Spaces bucket | State key |
| --- | --- | --- |
| `dev` | `treetracker-dev-terraform` | `terraform-kubernetes.tfstate` |
| `test` | `treetracker-test-terraform` | `terraform-kubernetes.tfstate` |
| `prod` | `treetracker-production-terraform` | `terraform-kubernetes.tfstate` |

After configuring your Spaces credentials, initialize the selected environment.
For example, from this directory:

```sh
terraform -chdir=dev init
```

No separate `backend-config.tfvars` file or bucket prompt is needed. If an
existing checkout reports a backend configuration change after updating, run
`terraform -chdir=dev init -reconfigure` for the selected environment. The bucket
names and state keys are unchanged, so no state migration is required.
