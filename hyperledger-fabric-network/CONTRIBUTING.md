# Contributing

Keep deployment changes limited to the six Fabric components in README. Runtime
credentials and identity artifacts must stay outside Git. Preserve stable node
names, namespaces and claim names unless the change includes a reviewed migration.

Before a change is merged, run `make validate`, review both profile renders and
update the component documentation and external-input contract if references
changed. Submit image updates with a verified digest and a Fabric compatibility
and rollback plan. A green render/lint run is not a runtime acceptance test.

The desired upstream location is `treetracker-infrastructure/hyperledger-fabric-network/`.
Copy this directory's contents there; do not add another nested network directory.
Merge the provided workflow into the upstream repository's root `.github/workflows/`
so GitHub runs it. Review existing upstream files before copying; preserve unrelated
content. No Git commit or remote change is performed by the supplied scripts.
