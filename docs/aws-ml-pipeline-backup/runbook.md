# Backup runbook - dormant ML pipeline (account $ACCOUNT_ID)

The destination deliverable of the `aws-data-backup` wayfinder effort. It assembles the decisions in `map.md` (tickets 01-09) into one executable procedure: back up all real data as portable files to a new S3 archive, restore-verify each artifact, then gate deletion of the sources on a manifest. Execution is a separate effort; this document is what the executor follows.

Supporting reference: [data-loss-risk-register.md](data-loss-risk-register.md). The manifest template and the executor IAM policy template are kept with the team's internal backup plan (not in this docs set).

## Configuration - set these before you start

Fill in these values for your AWS account. Keep them in a private place. Do not commit real values to git. Every step below uses the token, not the real value.

| Token | Set it to |
|-------|-----------|
| `$ACCOUNT_ID` | your 12-digit AWS account ID |
| `$ARCHIVE_BUCKET` | your archive bucket name (globally unique, for example an organisation prefix plus the account ID) |
| `$UNLOAD_ROLE_ARN` | the full ARN of your redshift-unload-role |
| `$BREAKGLASS_ROLE_ARN` | the full ARN of the admin role that may delete from the bucket |

Replace each `$TOKEN` with its real value at run time.

## 0. Principles (non-negotiable)

1. **Never delete a source until its manifest row is `backed_up && integrity_verified && restore_verified`** (or `skipped && skip_confirmed`), and the whole in-scope list has a named human sign-off (section 6). The bucket has no versioning/Object Lock (ticket 05), so the manifest gate + restore test are the ONLY safety net.
2. **Never pipe a producer straight to `aws s3 cp -`.** `pg_dump | s3 cp` and `tar | s3 cp` return the uploader exit code and hide a truncated artifact. Write to a local file (or `set -o pipefail` + check `PIPESTATUS`), then verify.
3. **Capture everything.** Full-filesystem tar (not curated dirs) for EBS; enumerate all partitions/LVM. `TransferMode=ALL` for DataSync. Reconcile Redshift tables vs `SVV_TABLES`.
4. **Reproduce before you trust.** Dry-run each method on ONE resource and pass its restore test before running the rest.

## 1. Scope - frozen inventory (ticket 08)

18 resources in scope, NONE skipped outright. Regions: eu-central-1, eu-north-1, us-east-1, us-east-2, us-west-2.

| # | Resource | Service | Region | Size | Note |
|---|----------|---------|--------|------|------|
| 1 | database-1 (Aurora PG) | rds | eu-central-1 | 50 MB | private |
| 2 | database-1 (RDS PG t4g) | rds | eu-north-1 | 1.67 GB | public |
| 3 | redshift-serverless-namespace-atnpoq5hrgobah | redshift | us-east-2 | 0.85 GB | |
| 4 | vol-04fe0d7cba9b38fb9 | ebs | eu-central-1 | 200 GB | root, stopped i-036 |
| 5 | vol-0ed3b832cc0d0876b | ebs | eu-central-1 | 32 GB | root, running i-04b (persistent Spot, writes daily) |
| 6 | vol-0daa47086adb31f5b | ebs | us-east-2 | 16 GB | root, stopped i-08f |
| 7 | vol-025852864691d4ca3 | ebs | us-west-2 | 8 GB | root, running i-0e1 (writes daily) |
| 8-9 | vol-091d83e578b18505d, vol-04dd64f4d9aa95633 | ebs | eu-central-1 | 64 GB each | CONDITIONAL: inspect then decide |
| 10 | fs-05582d671012af6ef | efs | us-east-1 | 161 GiB | |
| 11-12 | fs-8bffa6d3, fs-0b442f984b7eabc96 | efs | eu-central-1 | 36 + 20 GiB | fs-0b44: stop live app first |
| 13-18 | fs-0e8cfbd8, fs-0bf4d204, fs-0851b118, fs-0928a181, fs-03128cb8 (us-east-1), fs-03c9b50d (us-east-2) | efs | us-east-1/2 | <1 MB each | empty, back up anyway |

Live re-check 2026-09-23: all 18 resources are unchanged (same IDs, sizes, states). No new resource exists in any Region. Both RDS databases and the 3 non-empty EFS had zero connections/writes from 2026-09-09 to 2026-09-22.

Out of scope: S3-resident ML buckets (already durable in S3), SageMaker metadata/config, Treetracker production data.

## 2. Prerequisite: one-time SETUP (admin) - ticket 09

`arnold-cli` is ReadOnly and cannot do this. An admin must:
1. Create archive bucket `$ARCHIVE_BUCKET` (eu-central-1): Block Public Access ON; default SSE-S3; TLS-only + `Deny s3:DeleteObject` + `s3:DeleteObjectVersion` bucket policy (break-glass admin excepted); NO versioning, NO Object Lock; lifecycle = transition to Glacier Instant Retrieval after the restore-test window, NO Expiration rule.
2. Create 3 service roles: `redshift-unload-role` (trust redshift), `datasync-s3-write-role` (trust datasync), `backup-helper-ec2-profile` (trust ec2 + kms:Decrypt) - each with S3 write to the bucket.
3. Create `aws-data-backup-executor` role with the executor IAM policy template; grant to the operator/agent.
4. Protect the sources until the deletion gate (section 6). On 2026-09-23 no source had protection: RDS deletion protection was off on both databases, the eu-north-1 automated backup retention was 1 day, all 4 EBS root volumes had `DeleteOnTermination=true`, and only i-036 had termination protection.
```
# RDS: block deletion (apply immediately, no downtime)
aws rds modify-db-instance --region eu-north-1 --db-instance-identifier database-1 --deletion-protection --backup-retention-period 7 --apply-immediately
aws rds modify-db-cluster  --region eu-central-1 --db-cluster-identifier database-1 --deletion-protection --apply-immediately
# EC2: keep each root volume if its instance is terminated (CLI only for an existing instance)
aws ec2 modify-instance-attribute --region eu-central-1 --instance-id i-036ee8c22d5fb646a --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region eu-central-1 --instance-id i-04bb0c9954b2fb870 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region us-east-2    --instance-id i-08f3d846b35606e62 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region us-west-2    --instance-id i-0e1753f684b3971e7 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
# EC2: termination protection (On-Demand only; AWS does not allow it on the Spot instance i-04b)
aws ec2 modify-instance-attribute --region us-east-2 --instance-id i-08f3d846b35606e62 --disable-api-termination
aws ec2 modify-instance-attribute --region us-west-2 --instance-id i-0e1753f684b3971e7 --disable-api-termination
```
Confirm: `describe-db-instances` / `describe-db-clusters` show `DeletionProtection=True`; `describe-instances` shows `DeleteOnTermination=false` on each root volume.

All backup commands below run as `aws-data-backup-executor`.

## 3. Backup steps (per service)

Prefix scheme: `s3://$ARCHIVE_BUCKET/backup-2026-09/<service>/...`.

### 3.1 RDS (resources 1-2) - pg_dump

For each DB (public DB2 direct; private Aurora DB1 from an in-VPC helper EC2 or SSM port-forward):
```
# client pg_dump major version must be >= server version
PGPASSWORD=<pw> pg_dump -h <endpoint> -p 5432 -U <user> -d <db> -Fc -Z 6 -v -f <db>.dump   # confirm exit 0
pg_restore --list <db>.dump >/dev/null                                                        # must succeed (not truncated)
aws s3 cp <db>.dump s3://.../backup-2026-09/rds/<region>/<db>/ --checksum-algorithm SHA256
# once, cluster-wide globals:
PGPASSWORD=<pw> pg_dumpall -h <endpoint> -U <user> --globals-only --no-role-passwords -f globals.sql
aws s3 cp globals.sql s3://.../backup-2026-09/rds/<region>/<db>/ --checksum-algorithm SHA256
```
Do NOT pipe pg_dump to s3. Export parameter-group settings separately (config, not row data). Passwords are lost with `--no-role-passwords`; re-set on restore.

### 3.2 Redshift (resource 3) - UNLOAD to Parquet

1. Attach `redshift-unload-role` to the namespace (`update-namespace --iam-roles`, preserve existing roles).
2. Enumerate base tables (exclude views + system schemas) via `redshift-data execute-statement` on `svv_tables WHERE table_type='base tables'`.
3. Per table:
```
UNLOAD ('SELECT * FROM "schema"."table"')
TO 's3://.../backup-2026-09/redshift/dev/schema/table/'
IAM_ROLE '$UNLOAD_ROLE_ARN'
FORMAT PARQUET ALLOWOVERWRITE PARALLEL ON MANIFEST VERBOSE REGION 'eu-central-1';
```
4. Reconcile the archived table list vs `SVV_TABLES` (empty tables write no file - catch them). Script all DDL/views/procs/UDFs/grants to `_ddl/` (UNLOAD is row-data only). Type traps: unload VARBYTE/GEOMETRY/GEOGRAPHY/HLLSKETCH as CSV/JSON; SUPER as JSON; convert TIMESTAMPTZ to UTC or store the offset (Parquet drops it).

### 3.3 EFS (resources 10-18) - DataSync

For fs-0b44 (resource 12), STOP its SageMaker Studio app first (live writes = torn copy). Per filesystem:
1. Create EFS source location (subnet in the FS VPC/AZ + SG allowing NFS 2049) and S3 destination location (`datasync-s3-write-role`, prefix `backup-2026-09/efs/<fs-id>/`).
2. Create a **Basic mode** task, options: `VerifyMode=POINT_IN_TIME_CONSISTENT`, `TransferMode=ALL`, Copy ownership/permissions/timestamps = PRESERVE, `LogLevel=TRANSFER` + a Task Report.
3. Run; the us-east-1 FS is cross-region to the eu-central-1 bucket (agentless; expect egress cost).
4. Confirm `FilesFailed=0` and every `FilesSkipped` is expected.

### 3.4 EBS (resources 4-9) - snapshot -> clone -> full-fs tar

One helper Linux EC2 per region (eu-central-1, us-east-2, us-west-2). For resources 8-9, mount read-only and INSPECT first; skip only if provably empty, else back up. For running instances (i-04b, i-0e1), STOP the instance before the snapshot. This step is mandatory, not optional: on 2026-09-23 both root volumes wrote 0.2-0.8 GB per day, so a live snapshot can capture torn files. Ask the owners what writes this data before you stop the instance.

**i-04b is a persistent Spot instance (request `sir-ftc8krtp`).** When you stop it, its Spot request goes to `disabled`. **Do NOT cancel the Spot request while the instance is stopped: AWS then terminates the instance automatically.** Do not terminate the instance. If a termination occurs, the `DeleteOnTermination=false` setting from SETUP step 4 keeps the root volume, but the instance is lost.
```
aws ec2 create-snapshot --region <SRC> --volume-id <VOL>; aws ec2 wait snapshot-completed ...
aws ec2 create-volume --region <HELPER> --availability-zone <HELPER_AZ> --snapshot-id <SNAP> --volume-type gp3
aws ec2 attach-volume --volume-id <NEW> --instance-id <HELPER> --device /dev/sdf
lsblk -f; pvs; vgs; lvs; vgchange -ay          # enumerate ALL partitions/LVM - mount every FS found
mount -o ro,nouuid /dev/nvme1n1p1 /mnt/src
set -o pipefail
sudo tar -S --acls --xattrs --numeric-owner -czf - -C /mnt/src . \
  | aws s3 cp - s3://.../backup-2026-09/ebs/<VOL>/data.tar.gz --expected-size <BYTES> --checksum-algorithm SHA256
echo "${PIPESTATUS[@]}"                          # both must be 0
```
`--expected-size` is mandatory (>50 GB else the 10,000-part cap fails). Full-filesystem tar per partition (not curated dirs). Delete clones + copied snapshots after verify; NEVER touch sources.

## 4. Manifest & integrity (ticket 06)

Fill the manifest template as you go: one row per resource with `artifact_s3_keys`, `object_count`, `total_bytes`, `checksums` (SHA-256 for single files, tool-manifest + aggregate for multi-object sets), `source_metric`, and the `status` booleans. Write it to `s3://.../backup-2026-09/manifest.json` (write-once) AND commit a copy into this repo dir. It is the single source of truth.

## 5. Restore-verification (ticket 07)

Verify while artifacts are in S3 Standard, before the GIR transition. Throwaway scratch resources, torn down after. Reuse the EBS helper EC2 as the verify host.
- RDS: `pg_restore --list` OK + restore into a scratch DB + per-table row counts match source; `globals.sql` replays.
- Redshift: reload each table via `COPY ... MANIFEST` into a scratch Serverless workgroup + row counts match + DDL replays.
- EFS: object-count + total-bytes match the DataSync Task Report + random-sample checksums match + `FilesFailed=0`.
- EBS: `aws s3 cp - | tar tzf -` lists cleanly + all partitions present + spot-extract known files.
Each pass sets `restore_verified=true` + evidence in the manifest.

## 6. Deletion gate (ticket 06)

A source may be deleted ONLY when its manifest row is `backed_up && integrity_verified && restore_verified` (or `skipped && skip_confirmed`). The deletion effort may begin ONLY when EVERY in-scope row passes AND a named human records `gate.all_rows_satisfied=true` + `gate_approved_by` + `gate_approved_at`. Deletion itself is a separate effort. That effort must first remove the SETUP step 4 protections (RDS deletion protection, EC2 termination protection). The root volumes then stay after instance termination (`DeleteOnTermination=false`), so it must delete them explicitly.

## 7. Ordering & teardown

1. SETUP (section 2).
2. Backup all 18 resources (section 3). Dry-run one per service first.
3. Fill the manifest (section 4).
4. Restore-verify (section 5), in Standard.
5. Human sign-off on the manifest gate (section 6).
6. Let the lifecycle transition artifacts to GIR.
7. (Separate effort) delete sources, then the archive stays indefinitely.
Teardown after verify: delete all scratch/verify resources, clone volumes, and copied snapshots. Leave sources untouched until the gate is signed.
