# database-grants/tuning

Operator-applied SQL for database tuning that Terraform cannot express.

These files change PostgreSQL configuration parameters at the role or database level (for
example `work_mem`). They are **not** managed by Terraform: the `cyrilgdn/postgresql` provider
(1.22.0) used in `../terraform/` has no resource for a per-role, per-database configuration
parameter (the `ALTER ROLE ... IN DATABASE ... SET` form). It also does not model `work_mem` on
the `postgresql_role` resource. So these settings live here as reviewable, reversible SQL that a
database administrator applies by hand.

## How to apply

A DBA runs the SQL against the production cluster using the `doadmin` account (the CI service
account is intentionally not permitted to change production data). Each file documents its own
apply, verify, and rollback steps in header comments.

For role-level session defaults (such as `work_mem`), the new value only takes effect for **new**
backend sessions at login time. When the client connects through pgpool, recycle the pgpool
connection pool after applying so the pooled connections pick up the new value.

## Relationship to Terraform

Terraform in `../terraform/` owns role identity, membership, and grants (when applied). The
settings here are a separate, non-overlapping concern: the provider does not track them, so a
`terraform apply` will neither create nor revert them. There is no drift on these parameters.

Note on activation: at the time of writing, the `database-grants` Terraform is applied manually
(there is no CI apply), and whether prod state is currently reconciled has not been confirmed
from the remote state. This does not affect the tuning files here, because the provider does not
model these parameters either way.

## Files

- `prod/work_mem-readonlyuser.sql` - raises `work_mem` to 64MB for `readonlyuser` on the
  `treetracker` database, to cut temporary-file spill from the tile-map read queries.
