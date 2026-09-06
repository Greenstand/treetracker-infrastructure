# TreeTracker deployment guide

## 1. Prepare the platform

Use Kubernetes 1.26+ with a matching kubectl, Helm 3.21.3, Python 3.10+ and the
pinned Python requirements. The production chart requires at least five
schedulable workers for orderer anti-affinity. Size CPU/memory from the rendered
requests and expected throughput; defaults are the inspected deployment baseline,
not a throughput sizing guarantee. The 39 claims request 263 GiB before backups.

Provide an enforcing CNI, cluster DNS, encrypted CSI storage and external backup
and recovery procedures. The default existing StorageClass is `fabric-retained`
with Retain reclamation and WaitForFirstConsumer. To choose another class, create
an operator override outside the tracked configuration:

```yaml
# <overrides-dir>/storage.yaml
storageClass: your-encrypted-retained-csi-class
```

Overrides are one file per chart: `ca.yaml`, `orderer.yaml`, `peers.yaml`,
`couchdb.yaml`, `chaincode.yaml`, `storage.yaml`. Pass the same `--overrides-dir`
to render, preflight, deployment and validation. Credentials must not go in values.
Keep the three namespace names: service DNS and identity SANs depend on them.

## 2. Validate and provision storage

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
make validate
./scripts/preflight.sh --component storage --context production --live
./scripts/deploy-treetracker-network.sh --component storage --context production --apply
```

The deployment script creates the three required namespaces when installing the
storage chart. Storage installation deliberately does not wait for PVC binding:
WaitForFirstConsumer claims bind only when their consuming pods are scheduled.
The eight unmounted legacy claims can remain Pending on a fresh CSI installation;
the other 31 should bind once their workloads start. A brand-new deployment can
omit the old claims with `includeLegacy: false`; use `--component storage` for
that installation since the full-inventory validator expects all 39.

## 3. Bootstrap CAs

Provision these Secrets in `hlf-ca`, each with owner-managed `username` and
`password` keys: `fabric-root-ca-bootstrap`, `cbo-ca-bootstrap`,
`greenstand-ca-bootstrap`, `investor-ca-bootstrap`, and `verifier-ca-bootstrap`.
Generate unique credentials in your secret management system.

The import helper accepts files from outside the repository:

```text
<identity-input-dir>/
└── hlf-ca/
    ├── fabric-root-ca-bootstrap/{username,password}
    ├── cbo-ca-bootstrap/{username,password}
    ├── greenstand-ca-bootstrap/{username,password}
    ├── investor-ca-bootstrap/{username,password}
    └── verifier-ca-bootstrap/{username,password}
```

Files backing Secret keys must have owner-only permissions. First validate, then
explicitly import and deploy:

```bash
python3 scripts/import-identities.py --component ca --input-dir /secure/fabric-inputs
python3 scripts/import-identities.py --component ca --input-dir /secure/fabric-inputs --context production --apply
./scripts/preflight.sh --component ca --context production --live
./scripts/deploy-treetracker-network.sh --component ca --context production --apply
```

The helper refuses to overwrite any existing identity. Use the established
rotation workflow for an existing network. On empty PVCs the CA initializes its
database and keys once, then reuses that CA home on restart. Bootstrap credentials
are not a method for replacing lost CA keys. Back up each complete CA home.

The four organization CAs in this baseline are independent roots. If your target
requires intermediate CAs, first establish the intended PKI hierarchy and
configure parent enrollment credentials through Secret-backed environment values.
Do not start independent organization roots and later assume their identities
belong to a newly introduced hierarchy.

## 4. Enroll and supply runtime identities

Use Fabric CA client enrollment against the five TLS CA endpoints. Register each
peer as type `peer`, each orderer as type `orderer`, and each organization admin
as type `admin`. Each enrollment must have its own private key. Enroll TLS
identities with SANs matching the actual service names/FQDNs. Verify certificate
chains and role OUs against the channel MSP before admitting identities.

The [Fabric CA operations guide](https://hyperledger-fabric-ca.readthedocs.io/en/latest/operations_guide.html)
describes enrollment. Run enrollment from a secured operator environment with
the CA's TLS root and registered credentials; do not disable verification.

`./scripts/preflight.sh` lists every external input for the rendered configuration.
The checked-in list is also in `config/required-inputs.yaml`. The key layouts are:

| Input | Required key layout |
| --- | --- |
| `<peer-name>-certs` | `msp-cert`, `msp-key`, `msp-cacert`, `tls-cert`, `tls-key`, `tls-cacert` |
| `ordererN-msp`, `v2-ordererN-msp` | `signcerts.cert.pem`, `cacerts.cert.pem`, `admincerts.cert.pem`, `keystore.key` |
| `ordererN-tls`, `v2-ordererN-tls` | `server.crt`, `server.key`, `ca.crt` |
| `orderer-admin-client-ca` | `ca.crt`: the approved administration client issuing CA |
| `chaincode-tls`, `token-chaincode-tls` | `tls.crt`, `tls.key` |
| `couchdb-credentials` | `username`, `password` |
| Registry pull Secrets | `.dockerconfigjson` |
| `cbo-current-root`, `greenstand-current-root` ConfigMaps | `current-ca.pem` |

Put the contents under `<identity-input-dir>/<namespace>/<object-name>/<key>`.
Create registry credentials for every namespace in which they are referenced.
Use import-identities with `--component` to import only the component inputs in
an otherwise empty namespace, or use your existing secret delivery system.
The shared CouchDB credential and shared registry references need importing only
once. Use `--skip-existing` during staged imports to retain existing objects after
checking their key names; it never rotates or overwrites them.

Copy public organization MSPs and the ten orderer TLS certificates to the ignored
paths documented in `config/README.md` for configtxgen. Private administrative MSPs
stay outside this repository. Preflight checks object/key presence only; it does
not certify expiry, TLS SANs, matching key pairs, channel trust or registry access.

## 5. Deploy the remaining components

```bash
./scripts/preflight.sh --context production --live
./scripts/deploy-treetracker-network.sh --component couchdb --context production --apply
./scripts/deploy-treetracker-network.sh --component orderer --context production --apply
./scripts/deploy-treetracker-network.sh --component peers --context production --apply
./scripts/deploy-treetracker-network.sh --component chaincode --context production --apply
```

Alternatively, after all inputs exist, run the full deployment command. It
installs storage, CAs, CouchDB, orderers, peers and chaincode in that order.
Each compute release waits up to 15 minutes. Commands stop on failure. There is
no cross-release transaction or automatic rollback of persistent data.

## 6. Create or restore channels

For a **new network only**, generate the successor block after its public MSPs
and consenter certificates are in place:

```bash
./scripts/create-channels.sh generate --channel treetracker-v2 --block /secure/artifacts/treetracker-v2.block
# Review the command; add --execute to generate the block.
```

For each of `v2-orderer0..4`, run the following from a host with DNS/network
access to the service. Its admin client certificate must be trusted by
`orderer-admin-client-ca`; the orderer server certificate must match the endpoint.

```bash
./scripts/create-channels.sh join-orderer --channel treetracker-v2 \
  --block /secure/artifacts/treetracker-v2.block \
  --orderer-admin v2-orderer0.hlf-orderer.svc.cluster.local:9444 \
  --orderer-tls-root /secure/orderer-server-ca.pem \
  --admin-cert /secure/orderer-admin-client.pem --admin-key /secure/orderer-admin-client.key \
  --execute
```

Join each CBO and Greenstand peer using that organization's administrative MSP:

```bash
./scripts/create-channels.sh join-peer --channel treetracker-v2 \
  --block /secure/artifacts/treetracker-v2.block \
  --msp-id GreenstandMSP --msp-dir /secure/greenstand-admin/msp \
  --peer peer0-greenstand.hlf-peer-org.svc.cluster.local:7051 \
  --peer-tls-root /secure/greenstand-peer-tls-ca.pem --execute
```

Repeat for all five members. For a new original ordering group, use the
`treetracker` profile and `orderer0..4` endpoints. For an existing network, restore
the original ledger storage and use its authentic blocks. The generated profile
cannot reproduce historical config blocks or cure the legacy CBO governance lockout.

## 7. Chaincode and verification

Follow the [integration manual](TREETRACKER_INTEGRATION_MANUAL.md) to package,
install, approve and commit both contracts. Service pods alone do not install
contracts on peers or commit definitions to a channel.

```bash
./scripts/test-network.sh --context production --channel treetracker-v2
```

This checks workload readiness and participating peer height/hash agreement.
It performs no ledger write. Before production acceptance, independently test
contract queries and an approved transaction, orderer failover, certificate
rotation, node loss, capacity and a restore from an off-cluster backup.

## Troubleshooting

- Pending orderers: check required anti-affinity, node resources/taints and CSI binding.
- ImagePullBackOff: check the namespace's private registry pull Secret and image access.
- FailedMount: run preflight and compare required Secret/ConfigMap keys.
- CBO Readers errors on `treetracker`: this is an existing channel trust/governance issue;
  use the active channel or the authorized recovery process, not new genesis blocks.
- Helm ownership or immutable-field errors: stop and follow `MIGRATION.md`.
- Ready pod but failed transaction: inspect MSP trust, channel membership, installed
  package IDs, committed sequence, endorsement policy and chaincode TLS roots.
