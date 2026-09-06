# TreeTracker operator manual

## Inspect the network

Always choose a context explicitly. These commands are read-only:

```bash
kubectl --context production -n hlf-ca get pods,pvc,svc
kubectl --context production -n hlf-orderer get pods,pvc,svc
kubectl --context production -n hlf-peer-org get pods,pvc,svc
./scripts/preflight.sh --context production --live
./scripts/test-network.sh --context production --channel treetracker-v2
```

Healthy Kubernetes pods are necessary but do not establish channel health.
The test queries all five declared participants and compares height and block
hash. The three unjoined Investor/Verifier peers are checked for workload readiness
but are not treated as channel participants.

## Logs and events

```bash
kubectl --context production -n hlf-orderer logs deployment/v2-raft-orderer-0 --since=15m --tail=100
kubectl --context production -n hlf-peer-org logs peer0-greenstand-0 -c peer --since=15m --tail=100
kubectl --context production -n hlf-ca get events --field-selector type=Warning
```

Avoid printing Secret values or full unredacted configuration dumps into tickets.
Use `config/required-inputs.yaml` and the key-only preflight output to diagnose
missing references. CA homes and Fabric CLI logs can contain identity information;
handle them through the operator's access controls.

## Changes and maintenance

Keep per-environment changes in a reviewed overrides directory. Render and run
validation with those exact overrides before applying. Never increase replicas
of one peer, orderer or CouchDB identity; add another distinct identity/claim.

Peer StatefulSets use OnDelete. After a chart update, inspect its changed pod
template, then replace one peer pod at a time during maintenance. Confirm readiness,
channel reads and ledger agreement before replacing another. Orderer Deployments
also need a one-node-at-a-time upgrade plan: PDBs govern evictions, not Deployment
controller rollouts. The convenience full deployment script is for provisioning,
not a substitute for a quorum-aware maintenance sequence.

Singleton PDBs intentionally block eviction of the last ready instance. Arrange
a maintenance window or application-level redundancy before draining its node.
Do not delete PVCs to resolve scheduling or restart problems.

## Backups and restore

Back up CA homes, all orderer data, current peer ledger/package data, public
channel artifacts and externally managed identities. Preserve matching versions
and configuration. Use an application-consistent backup/restore procedure for
peer/CouchDB pairs. CouchDB is derived world state; the block ledger remains the
source for recovery, but a rebuild must use supported Fabric procedures.

Keep backups encrypted outside the cluster/host and test restoration in isolation.
The charts provide retained claims but install no backup controller and make no
automatic-backup claim. Retain policy protects deletion paths, not data corruption
or host loss. Preserve all eight old peer claims until recovery retention policy
explicitly permits their removal.

Do not generate new CA roots or channel genesis blocks when restoring an existing
network. Recover the identities and ledgers that the existing channel trusts.
