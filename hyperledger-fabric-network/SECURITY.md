# Security and identity handling

Report identity exposure through the owning organization's private security
channel. Do not include keys, passwords, kubeconfigs or registry auth in public
issues. This repository contains only references to external identities.

The import helper creates missing inputs and refuses overwrites. Its optional
skip-existing behavior checks only key names, not certificate validity or identity
equivalence. Rotation must be governed separately, especially for channel MSP roots
and Raft consenter certificates. Use owner-only files outside Git for private material.

Production values require an enforcing CNI, protected operations/admin access and
CSI-backed retained storage. No chart creates public Services, privileged workloads,
hostPath mounts or Kubernetes API RBAC grants. Private chaincode images retain their
image-defined UID, and all images retain their observed versions; review image
provenance, vulnerability status and admission compatibility before production use.

Backup encryption, off-cluster retention, certificate enrollment/renewal automation
and access to the private registries are platform responsibilities. These charts
do not claim to supply those services.
