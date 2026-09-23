# Data-loss risk register

Validated 2026-09-14 against AWS docs via the AWS Knowledge MCP. Scope: silent data-loss failure modes in the four backup methods (RDS, Redshift, EFS, EBS) and in the S3 archive itself, where a backup "succeeds" but data is missing/corrupt, so deleting the source becomes irreversible.

**A "silent" risk is the dangerous class:** the command returns success, but data is absent or corrupt, and the gap is found only at a future restore, after the source is gone.

## Top silent-loss vectors (fix these or do not delete the source)

1. **Piped upload hides a failed producer (RDS + EBS).** `pg_dump | aws s3 cp -` and `tar | aws s3 cp -` return the exit code of `aws s3 cp` (often 0), so a truncated dump/tarball uploads and looks successful. FIX: `set -o pipefail` + check `PIPESTATUS`; or dump to a local file, confirm exit 0, then upload; then a test-extract / `pg_restore --list` gate.
2. **EBS selective-directory tar misses data outside the guessed paths.** Scope is a human guess. FIX: tar the FULL filesystem of every mounted partition (`tar -C /mnt/x .`), not a curated dir list; enumerate all partitions/LVM first (`lsblk -f`, `pvs/vgs/lvs`, `vgchange -ay`). Optionally also retain the EBS snapshot as a block-level safety net.
3. **DataSync reports success while skipping files (EFS).** Enhanced mode verifies only transferred files; a "completed" task can hide `FilesSkipped`/`FilesFailed`. FIX: Basic mode + `VerifyMode=POINT_IN_TIME_CONSISTENT` + `TransferMode=ALL` to a fresh empty prefix; `LogLevel=TRANSFER` + Task Report; confirm `FilesFailed=0` and every skip is expected.
4. **Redshift empty tables write NO file (Redshift).** A zero-row table with PARALLEL ON produces no Parquet object, so the table (and its DDL) vanish silently. FIX: reconcile the archived table list against `SVV_TABLES`; script DDL for every table separately.
5. **SSE-KMS customer key deletion is permanent and irreversible.** After a 7-30 day window the whole archive is unreadable. FIX: use SSE-S3 (no customer-deletable key) for a delete-forever archive; pg_dump already removed any CMK requirement.
6. **Misconfigured lifecycle Expiration silently deletes archive objects; accidental delete removes them.** FIX: Object Lock (Compliance) + Versioning + zero Expiration rules.
7. **Consistency: crash-consistent snapshot / live-file copy corrupts data mid-write (EBS + EFS).** FIX: stop the instance/app or quiesce before snapshot/copy.
8. **Deletion before verification.** The single largest process risk. FIX: a source-independent gate: object present + checksum-verified + test-restore passed, recorded in a manifest, before any delete.

## Method A - RDS `pg_dump -Fc` + `pg_dumpall --globals-only`

| # | Risk | Sev | Silent | Mitigation |
|---|------|-----|--------|------------|
| A1 | Extension-owned table data not dumped unless registered (`pg_extension_config_dump`; PostGIS `spatial_ref_sys` is, ad-hoc state may not be) | Med | Yes | Test-restore + per-table row-count diff |
| A2 | Omits roles/passwords, tablespaces, cluster GRANTs, params. On RDS `rds_superuser` is not superuser, so `pg_dumpall` needs `--no-role-passwords` (passwords lost) | High | Yes | `pg_dumpall --globals-only --no-role-passwords`; export param-group; re-set passwords on restore. Config, not row data |
| A3 | `-Fc` single-connection = transactionally consistent; no torn state | Low | No | Use `-Fc` (or `-Fd -j` with synchronized snapshots) |
| A4 | **Truncated dump via a pipe uploads as "success"** (Serverless v2 pause / network drop) | High | Yes | `set -o pipefail`/PIPESTATUS, or dump-to-file-then-upload; gate on `pg_restore --list` + trial restore |
| A5 | `-Fc` truncation is detectable (TOC); `-Fp` plain SQL would be silently incomplete | Med | No | Always `-Fc`/`-Fd`, never `-Fp` |
| A6 | Param groups / cluster config invisible to pg_dump | Low | Yes | Export separately; recreatable config, not data loss |

## Method B - Redshift `UNLOAD ... FORMAT PARQUET`

| # | Risk | Sev | Silent | Mitigation |
|---|------|-----|--------|------------|
| B1 | VARBYTE/GEOMETRY/GEOGRAPHY/HLLSKETCH error on Parquet (loud); **TIMESTAMPTZ drops the tz offset silently** | High | Mixed | Unload those types as CSV/JSON; for TIMESTAMPTZ convert to UTC or store offset separately |
| B2 | SUPER best fidelity is JSON, not Parquet (ignores `NULL AS`) | Med | Yes | Unload SUPER as FORMAT JSON; reload with SERIALIZETOJSON |
| B3 | **Empty table + PARALLEL ON writes no file** - table + DDL silently absent | High | Yes | Reconcile archived list vs `SVV_TABLES`; script DDL per table |
| B4 | UNLOAD captures ROW DATA only - no DDL/DISTKEY/SORTKEY/views/procs/UDFs/grants | High | Yes | Script all DDL/objects/grants before delete (`SHOW`, catalogs) |
| B5 | MANIFEST VERBOSE = authoritative per-table file + row inventory | Low | No | Use MANIFEST VERBOSE; diff its row count vs source `COUNT(*)` |
| B6 | 6.2 GB per-file cap -> many files; a partial UNLOAD leaves gaps invisible without the manifest | Med | Yes | Trust MANIFEST; reload/verify with `COPY ... MANIFEST` (errors on missing file) |

## Method C - EFS DataSync

| # | Risk | Sev | Silent | Mitigation |
|---|------|-----|--------|------------|
| C1 | Verify scope: Enhanced mode / `ONLY_FILES_TRANSFERRED` do not compare the full tree | High | Yes | Basic mode + `VerifyMode=POINT_IN_TIME_CONSISTENT` (full-tree checksums) |
| C2 | Live/open files copied torn (running Studio app on fs-0b44) | High | Partly | Stop the app/quiesce writers first |
| C3 | Default `TransferMode=CHANGED` can skip files deemed unchanged | Med | Yes | `TransferMode=ALL` to a fresh empty prefix |
| C4 | Device/special files ignored silently; bad key paths (`/`, `//`, `/./`, `/../`) skipped | Med | Mixed | Confirm no device files hold data; avoid those prefixes; review skip counters |
| C5 | **Task can report "completed" with skipped/failed files** | High | Yes | `LogLevel=TRANSFER` + Task Report; confirm `FilesFailed=0`, skips expected |
| C6 | S3 representation restores metadata + empty dirs only via DataSync S3->EFS (not `aws s3 sync`) | Low-Med | Mixed | Restore only via DataSync; symlinks/hard links safe |

## Method D - EBS snapshot -> clone -> mount -> tar

| # | Risk | Sev | Silent | Mitigation |
|---|------|-----|--------|------------|
| D1 | **Selective tar misses data outside guessed paths** | High | Yes | Full-filesystem tar per mount; optionally keep the EBS snapshot as block-level safety net |
| D2 | Crash-consistent snapshot of a running instance corrupts mid-write files | High | Yes | Stop instance, or quiesce (freeze/flush/thaw) |
| D3 | **Broken tar pipe -> truncated object still "succeeds"** | High | Yes | `set -o pipefail`+PIPESTATUS; `--expected-size` for >50 GB; post-upload size check + test-extract |
| D4 | Encrypted volume without KMS grant | Med | No (fails loud) | Helper role needs `kms:Decrypt`+`kms:CreateGrant`; abort pipeline on clone failure |
| D5 | **Multi-partition / LVM: only one FS mounted, others skipped** | High | Yes | `lsblk -f`, `pvs/vgs/lvs`, `vgchange -ay`; archive every FS found |
| D6 | Sparse/special files, xattrs/ACLs not faithful | Med | Yes | GNU tar `-S --acls --xattrs --numeric-owner`; `-p` on restore; or block image |

## Method E - the S3 archive itself (post-source-deletion)

| # | Risk | Sev | Silent | Mitigation |
|---|------|-----|--------|------------|
| E1 | **SSE-KMS CMK deleted/revoked -> archive permanently unreadable** (7-30d window) | High | No | Prefer SSE-S3 (no deletable customer key); if KMS required, multi-Region key + locked policy + alarm on ScheduleKeyDeletion |
| E2 | Accidental delete/overwrite; versioning alone still allows version delete | High | Partly | Object Lock Compliance + long retain-until + Versioning; MFA Delete as defense-in-depth |
| E3 | **Misconfigured lifecycle Expiration silently deletes objects** | High | Yes | No Expiration rules; transition-only; Object Lock blocks lifecycle delete of locked versions |
| E4 | Single-region region-loss (S3 is 11 9s across >=3 AZ, so only full-region loss) | Med | No | Optional Cross-Region Replication (replicate lock state) for a critical archive |
| E5 | **Delete source before backup proven** | High | Yes | Source-independent gate: present + checksum-verified + test-restored, recorded in manifest |
| E6 | Deep Archive unreadable without a 12-48h restore job; 180-day min storage | Med | No | Verify + test-restore BEFORE transition to Deep Archive, or budget restore latency |

## Recommended archive-durability config

1. **Encryption:** SSE-S3 (no customer-deletable key). Use SSE-KMS only if audit control is mandatory - then a multi-Region key + locked policy + a CloudWatch alarm on any key-deletion attempt.
2. **Immutability:** Versioning ON + S3 Object Lock (Compliance) with a long retain-until-date + MFA Delete; **zero Expiration lifecycle rules**.
3. **Resilience + gate:** optional Cross-Region Replication; delete a source only after the manifest proves backup present + checksum-verified + test-restore passed; verify before any Deep Archive transition (or budget 12-48h).

## Where these feed

- Method safeguards (pipefail, full-fs tar, DataSync verify/transfer/log options, Redshift DDL+type handling, RDS globals+gate) -> method tickets 01-04 (mitigation notes appended).
- Manifest + completeness + checksum + the source-independent deletion gate -> issue 06.
- Restore-verification (test-restore per service; verify before Deep Archive) -> issue 07.
- Bucket durability (SSE-S3, Object Lock Compliance, no Expiration, optional CRR) -> issue 05.

## Update 2026-09-14 - archive immutability declined (ticket 05)

Owner chose NO versioning and NO Object Lock for the archive bucket. Consequence for E1/E2/E3:
- E1 (KMS key loss): N/A - default SSE-S3, no customer key. Risk removed.
- E2 (accidental delete/overwrite) + E3 (lifecycle expiry): the recommended Object Lock mitigation is NOT applied. Compensating controls only: BPA on, `Deny s3:DeleteObject*` bucket policy (soft - editable via `s3:PutBucketPolicy`), zero Expiration rules, unique dated write-once prefixes. A same-key overwrite is unrecoverable without versioning. Residual risk ACCEPTED by owner; the source-independent deletion gate (issue 06) + test-restore (issue 07) are now the primary safety net.

## Update 2026-09-23 - sources have no deletion protection (live re-check)

A live re-check found a 9th high-severity vector: **a source can be deleted before its backup by an unrelated action.**
- Both RDS databases had deletion protection off. The eu-north-1 automated backup retention was 1 day.
- All 4 EBS root volumes had `DeleteOnTermination=true`. Only i-036 had termination protection.
- i-04b is a persistent Spot instance. If you cancel its `disabled` Spot request while the instance is stopped, AWS terminates the instance, and with it the root volume. AWS does not allow termination protection on Spot instances.

FIX: runbook SETUP step 4 (console-runbook 1.5) turns on RDS deletion protection, sets 7-day retention on eu-north-1, sets `DeleteOnTermination=false` on the 4 root volumes, and turns on termination protection for i-08f and i-0e1. Never cancel the Spot request of a stopped i-04b. Source: AWS EC2 User Guide, "Manage your Spot Instances" and `ModifyInstanceAttribute` `DisableApiTermination`.

The same re-check made vector 7 (crash-consistent snapshot) concrete: the running instances i-04b and i-0e1 each write 0.2-0.8 GB per day. Stopping them before the snapshot is mandatory.

## Update 2026-09-23 - archive versioning ON (ticket 05 amendment)

Owner turned versioning ON for the archive bucket (Object Lock still NONE). Consequence for E2/E3:
- E2 (accidental delete/overwrite): a simple delete or a same-key overwrite is now undoable (the previous version stays as a noncurrent version). A permanent version delete (`DeleteObjectVersion`) is still possible for a principal that can edit the bucket policy. Residual risk reduced, not removed.
- E3 (lifecycle expiry): unchanged. Zero Expiration rules and no NoncurrentVersionExpiration.
- MFA Delete stays out: S3 does not allow it with a lifecycle rule.
