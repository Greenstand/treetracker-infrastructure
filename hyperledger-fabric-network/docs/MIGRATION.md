# Migrating an existing Fabric deployment to these charts

This repository was prepared without changing `kind-dev`. Its current CA,
orderer and peer namespaces are managed through separate Argo CD applications.
Helm cannot safely take those resources over merely because the names match.

## Differences to review

| Area | Chart behavior | Migration implication |
| --- | --- | --- |
| Original orderer Deployment selectors | Include channel label | Existing selectors are immutable; recreation is required |
| Shared orderer services | Both truly headless; selectors match all five nodes of their group | Existing v2 ClusterIP-to-headless change requires Service recreation |
| Peer StatefulSets | No volumeClaimTemplates; explicit active ledger claim; OnDelete update | Existing claim-template removal requires StatefulSet recreation |
| Storage ownership | Separate Helm release, all 39 claims retained | Do not let Argo prune or Helm replace data claims |
| Orderer administration | TLS with required trusted client certificate | Provision admin trust Secret and configure clients before restart |
| Image tags | Exact live digests | Ensure those registries are available to the target nodes |
| External builder | Executable, read-only ConfigMap | No busybox initialization or fabricated launch process |
| Peer local admincert mount | Removed; configured NodeOUs classify admins | Six live peer Secrets lack that legacy optional key; strict projections must not require it |
| CA initialization | Initialize only empty homes; no automatic TLS file renaming | Preserve real CA homes and explicitly plan any TLS rotation |
| CA metrics sidecars | Not deployed | Built-in metrics remain; standalone exporters are outside this scope |
| Network policy / scheduling | Production isolation and five-node anti-affinity | Use kind profile only for local environments |

## Controlled transition

1. Record the active context, Git revisions, workload configuration, exact PVC/PV
   mappings, channel heights/hashes and installed/committed chaincode definitions.
   Take verified off-cluster backups of identity material and ledger data. Establish
   a restore test and a maintenance window before changing ownership.
2. Render the charts and review the differences. Correctly provision the additional
   `orderer-admin-client-ca` Secret and verify the administration certificate/SAN
   chain. Keep the channel configurations unchanged during the packaging transition.
3. Coordinate Argo ownership per application, including disabling automatic
   reconciliation/pruning for the affected resources through the team's GitOps
   workflow. Do not let Argo and Helm reconcile the same object concurrently.
4. Initially reference every existing claim externally: set
   `claims.<name>.create: false` in the storage override. This avoids Helm adoption
   of bound PVCs. The compute charts still reference their unchanged names.
   A later reviewed ownership transfer may label/annotate claims for the storage
   release; this repository deliberately contains no automatic adoption script.
5. Transfer or recreate compute resources one identity at a time. Preserve the
   bound PVCs and Secret contents. For peer StatefulSet recreation, preserve its
   active `peer-ledger-couchdb-*` binding and avoid reverting to old `peer-data-*`
   storage. No operation should delete or reformat ledger directories.
6. For retained resources, Helm ownership is the release name and release namespace
   from README, plus `app.kubernetes.io/managed-by=Helm`. Review the exact resource
   list before any ownership metadata edits. Immutable fields need a controlled
   recreation, not `helm --force` or broad delete/reapply.
7. After each orderer change, check Raft membership/leader and delivery before
   proceeding. After each peer change, verify both channel membership and active
   ledger hash. Complete a governed evaluate/submit transaction check at the end.
8. Re-enable exactly one controller per resource and capture final ownership,
   recovery instructions and tested rollback boundaries in the platform repository.

The deployment helper detects conflicting ownership before installation and
does not use `--take-ownership`, `--force`, prune, PVC deletion or automatic
rollback. A failed Helm upgrade does not roll back ledger writes; restoring
previous manifests alone is not always a data rollback strategy.

## Legacy channel trust

The source recovery documentation describes a legacy CBO governance lockout and
the deployed `treetracker-v2` successor. Live inspection confirmed CBO Readers
failures on the original channel. This repository preserves both ordering groups
and documents that limitation. Recover authorized legacy CA/admin material or
use the successor through the established governance process; do not bypass
channel policy or manipulate orderer ledger files.
