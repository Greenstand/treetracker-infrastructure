# Validation evidence

Repository assembled from live `kind-dev` Fabric resources on September 6, 2026,
and organized using the linked TreeTracker infrastructure README. No Kubernetes
resources, Git commits or remote repositories were changed during packaging.

## Reference provenance

The live resources and these existing local source repositories informed the charts:

| Repository | Inspected local HEAD |
| --- | --- |
| HLF-Enterprise-Blockchain/hlf-ca | `8cf45140691b2b579a222944a59064d49dcbce00` |
| HLF-Enterprise-Blockchain/hlf-orderer | `4d491d6ff13de5885b0275ad01d0ba604c95244a` |
| HLF-Enterprise-Blockchain/hlf-peer-org | `adaf4b8a863212f34109857f21bb94bc02697eb8` |

Heads identify inspected source context, not a guarantee that every running
resource matches Git. The earlier orderer Argo application was OutOfSync.
Live image digests and runtime versions are documented in `config/images.lock.yaml`
and the architecture guide. Credentials and cluster-generated metadata were not
copied into the deliverable.

## Checks performed

- Helm 3.21.3 strict lint and template rendering for all six charts, production
  and kind profiles: passed.
- Kubernetes client-side dry-run/schema validation of both complete renders
  against the existing kubectl/API schema: passed. No create/update request was sent.
- Twelve behavioral regression tests: passed. Includes cross-group orderer
  isolation, service targets, exact inventory, active/legacy PVC wiring, identity
  input references, namespace validation, image pinning, credential rejection,
  per-node override isolation and deterministic chaincode package structure.
- Both channel profiles compiled into synthetic application genesis blocks using
  Fabric tools 2.5.16 in an isolated, network-disabled container: passed. Cryptogen
  identities and blocks existed only in container tmpfs and disappeared when it
  exited. This did not create or change real channels.
- Key-only live preflight: existing referenced identity keys were checked; the
  additional `hlf-orderer/orderer-admin-client-ca` Secret is a deployment prerequisite
  introduced by this repository's TLS-protected admin endpoint. It was not created.
- Repository scan for private-key bodies, known plaintext credential patterns,
  generated certificate/key/block archives, live volume bindings and cluster IDs:
  no such delivery artifacts found.

The expected production render contains 174 objects: 25 Deployments, eight
StatefulSets, 39 PVCs, 35 Services, 25 ServiceAccounts, 12 ConfigMaps, five
NetworkPolicies and 25 PDBs. The kind profile contains 144 objects because its
policies and PDBs are disabled. There are 33 workload pods in either profile.

## Reproduce

```bash
make validate
./scripts/render.sh --profile production | kubectl --context YOUR_CONTEXT create --dry-run=client -f - -o name
./scripts/render.sh --profile kind | kubectl --context YOUR_CONTEXT create --dry-run=client -f - -o name
# Optional: requires the exact tools image already present locally.
./scripts/test-config.sh
```

## Not established by these checks

No Helm release was installed into a new or existing cluster. No real CA
enrollment, channel join, chaincode definition change, contract transaction,
failover, backup/restore, image vulnerability assessment or throughput test was
performed. Production admission compatibility and runtime behavior of the
hardening changes need an isolated deployment acceptance run with valid external
identities and storage. Historic channel trust failures remain outside chart
packaging and require governance-led recovery.
