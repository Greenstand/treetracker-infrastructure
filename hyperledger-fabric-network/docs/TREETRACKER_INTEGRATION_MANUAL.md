# TreeTracker integration manual

## Client connections

Use the Fabric Gateway API on an enrolled peer with your application's own MSP
identity and TLS CA root. Names below are cluster DNS names, not public addresses.
Namespaces hosting clients must be admitted by the chart NetworkPolicy selector.
Do not use a peer's signing identity as an application credential.

| Endpoint | Protocol / purpose |
| --- | --- |
| `peer0-greenstand.hlf-peer-org.svc.cluster.local:7051` | TLS Fabric Gateway / endorser |
| `peer0-cbo.hlf-peer-org.svc.cluster.local:7051` | TLS Fabric Gateway / endorser |
| `v2-orderer0.hlf-orderer.svc.cluster.local:7050` | TLS ordering service, active group |
| `orderer0.hlf-orderer.svc.cluster.local:7050` | TLS ordering service, original group |
| `tree-contract-chaincode.hlf-peer-org.svc.cluster.local:9999` | TLS external chaincode; peer traffic only |
| `token-contract-chaincode.hlf-peer-org.svc.cluster.local:9998` | TLS external chaincode; peer traffic only |

The active channel is `treetracker-v2`. Contract names are `tree-contract` and
`token-contract`. Retrieve the actual committed definitions and application
source/ABI before calling functions; this deployment repository does not invent
REST routes or contract methods. The reserved `api/` directories contain no API
implementation or deployment.

## Chaincode packaging and lifecycle

The services use [Fabric external chaincode](https://hyperledger-fabric.readthedocs.io/en/release-2.5/cc_service.html).
Peers mount a read-only ConfigMap containing `detect`, `build` and `release`
builder scripts. No Docker socket, privileged builder or runtime internet
download is required.

Run Fabric 2.5 CLI tools from a secured workstation or operator environment with
cluster DNS access. Provide organization admin MSP files through the command
arguments; keys remain outside the repository. Examples print commands unless
`--execute` is included. Review the channel and sequence before executing.

1. Create one deterministic external package per contract, using the server's
   actual issuing CA certificate. Example for the tree service:

   ```bash
   ./scripts/deploy-chaincode.sh package --label tree-contract_1.0 \
     --address tree-contract-chaincode.hlf-peer-org.svc.cluster.local:9999 \
     --tls-root /secure/tree-chaincode-ca.pem \
     --package /secure/artifacts/tree-contract.tar.gz --execute
   ```

   Packaging prints the calculated package ID and refuses to overwrite a file.
   The TLS trust material and deterministic archive bytes determine the hash.
   Repackaging against a different CA or endpoint changes the ID.

2. Set that ID in a chart override before deploying the corresponding service:

   ```yaml
   # <overrides-dir>/chaincode.yaml
   nodes:
     tree-contract-chaincode:
       pod:
         containers:
           chaincode:
             env:
               CHAINCODE_CCID:
                 value: tree-contract_1.0:REPLACE_WITH_CALCULATED_HASH
   ```

   The default CCIDs are the observed deployed IDs, suitable only when restoring
   the matching installed packages. The repository contains the pinned service
   images, not the original package archives. A fresh enrollment usually requires
   new packages and new IDs. Apply only the chaincode Helm release with the same
   override directory after TLS Secrets exist.

3. Install the package on each of the five participating peers. Example:

   ```bash
   ./scripts/deploy-chaincode.sh install --package /secure/artifacts/tree-contract.tar.gz \
     --msp-id GreenstandMSP --msp-dir /secure/greenstand-admin/msp \
     --peer peer0-greenstand.hlf-peer-org.svc.cluster.local:7051 \
     --peer-tls-root /secure/greenstand-peer-tls-ca.pem --execute
   ```

4. Approve the definition once per participating organization, using its admin:

   ```bash
   ./scripts/deploy-chaincode.sh approve --channel treetracker-v2 \
     --name tree-contract --version 1.0 --sequence 1 \
     --package-id tree-contract_1.0:REPLACE_WITH_CALCULATED_HASH \
     --msp-id GreenstandMSP --msp-dir /secure/greenstand-admin/msp \
     --peer peer0-greenstand.hlf-peer-org.svc.cluster.local:7051 \
     --peer-tls-root /secure/greenstand-peer-tls-ca.pem \
     --orderer v2-orderer0.hlf-orderer.svc.cluster.local:7050 \
     --orderer-tls-root /secure/orderer-server-ca.pem --execute
   ```

   Repeat using CboMSP and its admin/peer. For an upgrade, query the current
   definition and choose the intended next sequence; never blindly reuse 1.

5. Run `check` with the same channel, name, version, sequence and peer/admin
   arguments. Confirm the required organizations have approved. Then run `commit`
   with the same definition, orderer TLS arguments, and both organizations'
   endorsement endpoints:

   ```text
   --endorser peer0-greenstand.hlf-peer-org.svc.cluster.local:7051
   --endorser-tls-root /secure/greenstand-peer-tls-ca.pem
   --endorser peer0-cbo.hlf-peer-org.svc.cluster.local:7051
   --endorser-tls-root /secure/cbo-peer-tls-ca.pem
   ```

   `--signature-policy`, `--collections-config`, and `--init-required` are optional
   but must be identical across approve/check/commit. If initialization is required,
   submit the contract's approved initialization transaction separately.

6. Run `query` with channel and peer/admin arguments to inspect committed
   definitions. Repeat the workflow for `token-contract`, service port 9998,
   its own TLS root, package label and CCID override.

Finish with application-specific evaluate and submit checks using valid test
data. The supplied read-only network test establishes readiness and ledger
agreement; it does not establish contract correctness or endorsement success.

## Certificate rotation

Rotate each identity under its issuing CA's policy. Update channel trust and
consenter TLS certificates through governance when necessary; Kubernetes Secret
replacement cannot change a channel's trusted roots. Refresh package trust and
CCIDs if a chaincode issuing root changes. Roll peers/orderers individually and
confirm ledger agreement before moving to the next node.
