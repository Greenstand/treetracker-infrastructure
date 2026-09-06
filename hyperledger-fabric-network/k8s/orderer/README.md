# TreeTracker ordering service

## Business role

A capture submission, review decision or token operation becomes part of the
shared history through Fabric's endorsement, ordering and validation stages.
Orderers sequence endorsed transactions into blocks. They do not decide whether
a photograph is valid or whether a token business rule is satisfied; chaincode,
endorsement and committing peer validation provide those other checks.

## Two independent five-member groups

| Group | Deployments | Client services | Channel role |
| --- | --- | --- | --- |
| Original | raft-orderer-0 through raft-orderer-4 | orderer0 through orderer4 | Original `treetracker` history |
| Successor | v2-raft-orderer-0 through v2-raft-orderer-4 | v2-orderer0 through v2-orderer4 | Active `treetracker-v2` integration |

Namespace: `hlf-orderer`. Each node has its own MSP, TLS identity and 5 GiB
claim. There are ten nodes and ten claims, not one ten-member Raft group.
Separate channel labels isolate selectors. The two shared `*-headless`
Services select all five members of their own group.

## Transaction architecture

```mermaid
sequenceDiagram
    participant API as Capture / token service SDK
    participant P as Endorsing peers
    participant O as Selected five-member ordering group
    participant C as Committing channel peers
    API->>P: Propose business operation
    P-->>API: Endorsed result and read/write set
    API->>O: Submit endorsed transaction
    O->>O: Agree on transaction order with Raft
    O-->>C: Deliver ordered blocks
    C->>C: Validate policy and state versions
    C->>C: Append ledger; apply valid writes
    C-->>API: Commit outcome / events
```

An ordered transaction can still be marked invalid by committing peers.
Capture/token APIs must correlate the actual commit outcome and transaction ID
rather than using orderer availability alone as proof of business success.

## Ports, identities and storage

| Port / input | Use |
| --- | --- |
| 7050 / TLS | SDK broadcast and peer block delivery |
| 9443 / HTTP | Internal health and metrics |
| 9444 / mutual TLS | Channel participation administration |
| `ordererN-msp`, `v2-ordererN-msp` | Signing certificate, CA, admin certificate and signing key |
| `ordererN-tls`, `v2-ordererN-tls` | Server/cluster TLS certificate, key and root |
| `orderer-admin-client-ca/ca.crt` | Approved issuer of administration client identities |
| `raft-orderer-data-N`, `v2-raft-orderer-data-N` | Ledger, WAL and snapshot persistence |

The chart defaults enable channel participation with no bootstrap block.
Starting on empty storage does not create a channel. Operators join the proper
authentic channel block via the separate lifecycle script.

## TreeTracker integration

Capture and token deployments currently configure the v2 ordering endpoint.
Their TLS roots and hostname overrides must match the selected group's identity.
The legacy CBO authorization/trust issue is a channel-governance condition:
moving Kubernetes resources into Helm does not cure it.

## Scheduling, upgrades and recovery

Production requires five schedulable nodes per group through hostname
anti-affinity; the same five nodes can host one member of each group.
A PDB retains at least three available members per group for voluntary eviction.
The kind overlay changes this to preferred placement and disables PDBs/policies.

Each Deployment uses Recreate because its identity has one RWO data volume.
PDBs do not serialize Deployment upgrades: change one orderer at a time, inspect
leader/quorum and delivery, then proceed. Preserve all data claims, MSPs and
consenter certificates during migration. Existing original selectors and the
v2 shared Service have immutable-field differences documented in
[MIGRATION](../../docs/MIGRATION.md).

## Helm usage and repository map

Run from the repository root:

```bash
./scripts/render.sh --component orderer --profile production
./scripts/preflight.sh --component orderer
./scripts/validate.sh --component orderer --profile production
# After external inputs, storage and ownership are reviewed:
./scripts/deploy-treetracker-network.sh --component orderer --context production --apply
```

`Chart.yaml` defines this release; `values.yaml` contains shared defaults and
named node overrides; `values.schema.json` validates value shape;
`values-kind.yaml` holds local relaxations; `templates/` renders the resources.
The kind profile disables policies/PDBs; orderer placement relaxations apply
only to the orderer chart. Rendering and preflight without `--live` are local.
For a live prerequisite check, add an explicit `--context` and `--live`.

See the [platform architecture](../../README.md#high-level-platform-architecture),
[deployment guide](../../docs/TREETRACKER_DEPLOYMENT_GUIDE.md),
[migration guide](../../docs/MIGRATION.md), and
[validation evidence](../../docs/VALIDATION.md).
