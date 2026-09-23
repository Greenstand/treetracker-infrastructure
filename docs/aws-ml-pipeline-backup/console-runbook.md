# Console runbook - backup before deletion (AWS Console UI)

The console (web UI) version of [runbook.md](runbook.md). Same decisions, same safeguards, expressed as click-by-click steps. Console navigation validated against AWS docs via the AWS Knowledge MCP on 2026-09-14.

## 0. Read first - what the console can and cannot do

Three operations cannot be pure console clicks because they need a shell: **pg_dump** (RDS), **tar/mount** (EBS). The console still hosts the shells, so they stay "in the console":
- **[CONSOLE]** = native clickpath (S3, IAM, DataSync, Redshift Query Editor v2, EC2 snapshot/volume actions).
- **[BROWSER SHELL]** = a terminal opened from the console: **AWS CloudShell** (footer/top-bar icon) or **EC2 Session Manager / EC2 Instance Connect** (Connect tab on an instance). You type commands there.

Non-negotiable safeguards carry over: never pipe `pg_dump`/`tar` straight to `aws s3 cp -` (write to a file or use `set -o pipefail`, then verify); full-filesystem tar; DataSync Basic mode with "Verify all data" + "Transfer all data"; a source is deleted only after its manifest row passes and a human signs the gate.

Scope = the 18 resources frozen in ticket 08 (see [runbook.md](runbook.md) section 1). Prefix scheme: `s3://$ARCHIVE_BUCKET/backup-2026-09/<service>/...`.

## Configuration - set these before you start

Fill in these values for your AWS account. Keep them in a private place. Do not commit real values to git. Every step below uses the token, not the real value.

| Token | Set it to |
|-------|-----------|
| `$ACCOUNT_ID` | your 12-digit AWS account ID |
| `$ARCHIVE_BUCKET` | your archive bucket name (globally unique, for example an organisation prefix plus the account ID) |
| `$UNLOAD_ROLE_ARN` | the full ARN of your redshift-unload-role |
| `$BREAKGLASS_ROLE_ARN` | the full ARN of the admin role that may delete from the bucket |

Replace each `$TOKEN` with its real value at run time.

---

## 1. SETUP (admin, one-time)

### 1.1 [CONSOLE] Create the archive bucket
S3 console -> **General purpose buckets** -> **Create bucket**.
1. **AWS Region**: Europe (Frankfurt) eu-central-1.
2. **Bucket name**: `$ARCHIVE_BUCKET`.
3. **Object Ownership**: ACLs disabled (recommended).
4. **Block Public Access**: keep **Block all public access** checked (all 4 ON).
5. **Bucket Versioning**: **Disable**.
6. **Default encryption -> Encryption type**: **Server-side encryption with Amazon S3 managed keys (SSE-S3)** (already the console default; confirm the radio).
7. **Advanced settings -> Object Lock**: **Disable**.
8. **Create bucket**.

### 1.2 [CONSOLE] Bucket policy (TLS-only + delete protection)
Open the bucket -> **Permissions** tab -> **Bucket policy** -> **Edit** -> paste, then **Save changes**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid":"DenyInsecureTransport","Effect":"Deny","Principal":"*","Action":"s3:*",
     "Resource":["arn:aws:s3:::$ARCHIVE_BUCKET","arn:aws:s3:::$ARCHIVE_BUCKET/*"],
     "Condition":{"Bool":{"aws:SecureTransport":"false"}}},
    {"Sid":"DenyDeleteExceptBreakGlass","Effect":"Deny","Principal":"*",
     "Action":["s3:DeleteObject","s3:DeleteObjectVersion"],
     "Resource":"arn:aws:s3:::$ARCHIVE_BUCKET/*",
     "Condition":{"ArnNotEquals":{"aws:PrincipalArn":"$BREAKGLASS_ROLE_ARN"}}}
  ]
}
```
Note: `s3:DeleteObject*` is NOT valid policy syntax; enumerate the two actions as above.

### 1.3 [CONSOLE] Lifecycle rule (Standard -> Glacier Instant Retrieval, no expiry)
Bucket -> **Management** tab -> **Create lifecycle rule**.
1. Name it; scope = **Apply to all objects** (tick the acknowledgement).
2. Action: check **Move current versions of objects between storage classes** ONLY (do NOT check any Expire/Delete action).
3. Transition storage class = **Glacier Instant Retrieval**; **Days after object creation** = e.g. 14 (after the restore test).
4. **Create rule**.

### 1.4 [CONSOLE] IAM policy + roles
IAM console -> **Policies** -> **Create policy** -> **JSON** tab. Create:
- `greenstand-ml-archive-s3-write` = PutObject/AbortMultipartUpload/ListBucket/GetBucketLocation on the bucket + `/*`.
- `aws-data-backup-executor-policy` = paste the executor IAM policy template.

IAM -> **Roles** -> **Create role** for each (Select trusted entity -> then Add permissions):
- **redshift-unload-role**: AWS service -> Redshift use case (or **Custom trust policy** with `redshift.amazonaws.com` + `redshift-serverless.amazonaws.com`); attach the s3-write policy.
- **datasync-s3-write-role**: **Custom trust policy** with `datasync.amazonaws.com` (DataSync is not in the service list); attach the s3-write policy. (You can also let DataSync autogenerate this in step 3.2.)
- **backup-helper-ec2-profile**: AWS service -> **EC2** use case (this auto-creates the matching instance profile); attach s3-write + a `kms:Decrypt`/`DescribeKey` policy; also attach **AmazonSSMManagedInstanceCore** (for Session Manager).
- **aws-data-backup-executor**: **Custom trust policy** naming the operator user/role ARN; attach the executor policy. Also give the operator `sts:AssumeRole` on this role.

Edit a trust later: role -> **Trust relationships** tab -> **Edit trust policy** -> **Update policy**.

### 1.5 [CONSOLE] + [BROWSER SHELL] Protect the sources until the deletion gate
On 2026-09-23 no source had protection: RDS deletion protection was off on both databases, the eu-north-1 automated backup retention was 1 day, all 4 EBS root volumes had `DeleteOnTermination=true`, and only i-036 had termination protection.
1. **[CONSOLE] RDS, eu-north-1:** RDS console -> **Databases** -> select `database-1` -> **Modify** -> **Deletion protection**: select **Enable deletion protection**; **Backup retention period** = 7 days -> **Continue** -> **Apply immediately** -> **Modify DB instance**.
2. **[CONSOLE] Aurora, eu-central-1:** select the cluster `database-1` (not its instance) -> **Modify** -> **Enable deletion protection** -> **Continue** -> **Apply immediately** -> **Modify cluster**.
3. **[CONSOLE] EC2 termination protection** (On-Demand only; AWS does not allow it on the Spot instance i-04b): EC2 -> **Instances** -> select i-08f (us-east-2), then i-0e1 (us-west-2) -> **Actions -> Instance settings -> Change termination protection** -> **Enable** -> **Save**.
4. **[BROWSER SHELL] Keep the root volumes** if an instance is terminated. The console has no option for an existing instance, so use CloudShell:
```
aws ec2 modify-instance-attribute --region eu-central-1 --instance-id i-036ee8c22d5fb646a --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region eu-central-1 --instance-id i-04bb0c9954b2fb870 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region us-east-2    --instance-id i-08f3d846b35606e62 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
aws ec2 modify-instance-attribute --region us-west-2    --instance-id i-0e1753f684b3971e7 --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":false}}]'
```
Confirm: each instance -> **Storage** tab -> root volume shows **Delete on termination: No**; each database -> **Configuration** tab shows **Deletion protection: Enabled**.

---

## 2. RDS (resources 1-2) - [BROWSER SHELL]

pg_dump needs a shell. Use a **helper EC2** (recommended: lets you dump to a scratch EBS file, verify, then upload - honoring the no-pipe rule) or **CloudShell** for the small private Aurora.

### 2.1 [CONSOLE] Find endpoint + open the network path
RDS console -> **Databases** -> pick the DB -> **Connectivity & security** tab: copy **Endpoint** + **Port**.
- Public DB (eu-north-1, resource 2): open its **VPC security group** -> **Inbound rules** -> **Edit** -> **Add rule** -> Type **PostgreSQL** (5432), Source **My IP** (or the helper's SG). Remove this rule after the dump.
- Private Aurora (eu-central-1, resource 1): do NOT expose it. Run pg_dump from inside the VPC (helper EC2 in the DB's VPC/subnet, or a **CloudShell VPC environment**), and allow that source SG on 5432.

### 2.2 [BROWSER SHELL] Dump, verify, upload
Open **CloudShell** (console footer/top-bar icon) or connect to the helper EC2 (section 4.3). Install the client: `sudo dnf install -y postgresql17`; confirm `pg_dump --version` >= server version. NOTE: CloudShell `$HOME` is only 1 GB and non-`$HOME` space is ephemeral, so for the 1.67 GB DB use a helper EC2 with a scratch volume, not CloudShell.
```
# dump to a FILE (not a pipe), confirm exit 0
PGPASSWORD=<pw> pg_dump -h <endpoint> -p 5432 -U <user> -d <db> -Fc -Z 6 -v -f <db>.dump
pg_restore --list <db>.dump >/dev/null      # must succeed = not truncated
aws s3 cp <db>.dump s3://$ARCHIVE_BUCKET/backup-2026-09/rds/<region>/<db>/ --checksum-algorithm SHA256
# once, cluster-wide globals:
PGPASSWORD=<pw> pg_dumpall -h <endpoint> -U <user> --globals-only --no-role-passwords -f globals.sql
aws s3 cp globals.sql s3://.../backup-2026-09/rds/<region>/<db>/ --checksum-algorithm SHA256
```
Then remove the temporary inbound SG rule from 2.1.

---

## 3. Redshift (resource 3) - [CONSOLE] Query Editor v2

### 3.1 Associate the unload role with the namespace
Amazon Redshift console (Region **US East (Ohio) us-east-2**) -> **Redshift Serverless** -> namespace `redshift-serverless-namespace-atnpoq5hrgobah` -> **Namespace configuration** -> **Security and encryption** tab -> **Permissions** -> **Manage IAM roles** -> **Associate IAM roles** -> tick `redshift-unload-role` -> **Associate IAM roles** -> **Save changes**.

### 3.2 Open Query Editor v2 and connect
Redshift console -> **Query editor v2** (opens a new tab) -> in the left tree right-click the Serverless workgroup -> **Create connection** -> Database `dev` -> **Create connection**.

### 3.3 Enumerate tables, then UNLOAD (run each in the editor, read the Results tab)
```sql
-- confirm the exact value your cluster uses, then filter on it
SELECT DISTINCT table_type FROM svv_tables;
SELECT table_schema, table_name FROM svv_tables
WHERE table_type IN ('base tables','BASE TABLE')          -- use whichever the line above shows
  AND table_schema NOT IN ('pg_catalog','information_schema','pg_internal');
```
Per table:
```sql
UNLOAD ('SELECT * FROM "schema"."table"')
TO 's3://$ARCHIVE_BUCKET/backup-2026-09/redshift/dev/schema/table/'
IAM_ROLE '$UNLOAD_ROLE_ARN'
FORMAT PARQUET ALLOWOVERWRITE PARALLEL ON MANIFEST VERBOSE REGION 'eu-central-1';
```
`REGION 'eu-central-1'` is required (bucket region != cluster region). Empty tables write NO file, so reconcile the archived prefixes against the table list. Type traps: unload VARBYTE/GEOMETRY/GEOGRAPHY/HLLSKETCH as CSV/JSON, SUPER as FORMAT JSON, and convert TIMESTAMPTZ to UTC (Parquet drops the tz offset).

### 3.4 Capture DDL (no generate-DDL button; run SQL)
`SHOW TABLE schema.table;` per table; `SELECT pg_get_viewdef('schema.view'::regclass, true);` per view. Save the output to `_ddl/` in the archive.

---

## 4. EFS (resources 10-18) - [CONSOLE] DataSync

For **fs-0b44** (resource 12): first stop its SageMaker Studio app (SageMaker console -> Studio -> delete the running app/space) so no file is copied mid-write.

### 4.1 Create the source location (per filesystem)
DataSync console, set Region = the filesystem's Region (us-east-1 for resource 10) -> **Data transfer -> Locations -> Create location** -> Location type **Amazon EFS file system** -> pick the file system, **Mount path** `/`, a **Subnet** in the same AZ as a mount target, a **Security group** allowing inbound NFS TCP 2049 -> **Create location**.

### 4.2 Create the S3 destination location
**Create location** -> **Amazon S3** -> **General purpose bucket** -> pick `$ARCHIVE_BUCKET` (eu-central-1) -> **S3 URI** folder `backup-2026-09/efs/<fs-id>/` -> **Storage class** = Standard -> **IAM role** = Autogenerate (or `datasync-s3-write-role`) -> **Create location**.

### 4.3 Create the task (Basic mode - required for full verification)
**Tasks -> Create task** -> source + destination locations from above -> **Configure settings**:
- **Task mode**: **Basic** (Enhanced mode cannot do full-tree verification; mode is fixed after creation).
- **Data verification**: **Verify all data** (= POINT_IN_TIME_CONSISTENT, full source+destination scan).
- **Transfer mode**: **Transfer all data**.
- **Metadata**: enable Copy ownership, Copy permissions, Copy timestamps.
- **Log level**: **Log all transferred objects and files**; set a CloudWatch log group.
- **Task report**: Standard report, **Successes and errors**, to a reports prefix (not the destination bucket).
- **Create task**.

### 4.4 Run and check
Select the task -> **Start** (start with defaults). When done, open the task execution: confirm **Files failed = 0** and every **Files skipped** is expected; read the **Task report** JSON in S3. Create the task in the SOURCE Region (us-east-1); the eu-central-1 bucket destination is handled cross-region, agentless.

---

## 5. EBS firm volumes (resources 4-7) - [CONSOLE] + [BROWSER SHELL]

Run per Region (eu-central-1, us-east-2, us-west-2).

**Stop the running instances first (mandatory).** For i-04b and i-0e1: EC2 -> **Instances** -> **Instance state** -> **Stop instance**. On 2026-09-23 both root volumes wrote 0.2-0.8 GB per day, so a live snapshot can capture torn files. Ask the owners what writes this data before you stop the instance.

**i-04b is a persistent Spot instance (request `sir-ftc8krtp`).** When you stop it, its Spot request goes to `disabled`. **Do NOT cancel the Spot request (EC2 -> Spot Requests) while the instance is stopped: AWS then terminates the instance automatically.** Do not terminate the instance.

### 5.1 [CONSOLE] Snapshot the source volume
EC2 console -> **Elastic Block Store -> Volumes** -> select the volume -> **Actions -> Create snapshot** -> **Create snapshot**.

### 5.2 [CONSOLE] (cross-region only) Copy the snapshot
EC2 -> **Snapshots** -> select (state Completed) -> **Actions -> Copy snapshot** -> set **Destination Region** = the helper's Region -> **Copy snapshot**. (Skip if the helper is already in the volume's Region.)

### 5.3 [CONSOLE] Create a volume from the snapshot + attach
**Snapshots** -> select -> **Actions -> Create volume from snapshot** -> **Availability Zone** = same AZ as the helper -> **Create volume**. Then **Volumes** -> select the new volume -> **Actions -> Attach volume** -> pick the helper instance -> **Device name** `/dev/sdf` -> **Attach volume**.

### 5.4 [CONSOLE] Launch + connect to the helper (once per Region)
EC2 -> **Launch instance** -> Amazon Linux 2023 -> `t3.micro` -> VPC/subnet in the helper AZ -> **Advanced details -> IAM instance profile** = `backup-helper-ec2-profile` -> **Launch instance**. Connect: **Instances** -> select -> **Connect** -> **Session Manager** tab -> **Connect** (needs the SSM instance profile above; no SSH key required).

### 5.5 [BROWSER SHELL] Enumerate, mount read-only, tar to S3
```
lsblk -f ; sudo pvs ; sudo vgs ; sudo lvs ; sudo vgchange -ay   # find EVERY partition/LV - archive them all
sudo mkdir -p /mnt/src
sudo mount -o ro,nouuid /dev/nvme1n1p1 /mnt/src                 # nouuid for XFS clone; use ext4 without nouuid
set -o pipefail
sudo tar -S --acls --xattrs --numeric-owner -czf - -C /mnt/src . \
  | aws s3 cp - s3://$ARCHIVE_BUCKET/backup-2026-09/ebs/<VOL>/data.tar.gz \
      --expected-size <BYTES> --checksum-algorithm SHA256
echo "${PIPESTATUS[@]}"                                          # BOTH must be 0
```
`--expected-size` is mandatory over ~50 GB (10,000-part cap). Repeat per partition if more than one.

---

## 6. EBS conditional volumes (resources 8-9) - [CONSOLE] + [BROWSER SHELL], inspect first

Same as section 5 but mount READ-ONLY and inspect before deciding:
```
sudo mount -o ro,nouuid /dev/nvme1n1p1 /mnt/x
du -xhd1 /mnt/x ; ls -la /mnt/x                                  # is there real data?
```
If empty/junk: mark the manifest row `skipped` + `skip_confirmed_by`. Else back up via section 5.5. (This is why arnold-cli cannot do it read-only: CreateSnapshot/attach need write perms; this is a ready-for-human step.)

---

## 7. Manifest & integrity - [CONSOLE]

Fill the manifest template: one row per resource with keys, sizes, checksums, source metrics, and the three status booleans. To read a stored SHA-256: S3 console -> the object -> **Properties** tab -> **Additional checksums** (shown base64). Upload the finished `manifest.json` to `backup-2026-09/manifest.json` (S3 -> **Upload** -> **Properties -> Additional checksums -> SHA-256 -> On**) AND commit a copy to the repo. It is the single source of truth.

---

## 8. Restore-verification - [CONSOLE] + [BROWSER SHELL]

Verify while artifacts are still in S3 Standard (before the GIR transition). Use throwaway scratch resources, delete them after.
- **RDS**: in a browser shell, `aws s3 cp` the dump back, `pg_restore --list`, restore into a scratch RDS/Postgres, compare per-table row counts.
- **Redshift**: in Query Editor v2 on a scratch Serverless workgroup, `COPY ... FROM 's3://.../table/manifest' IAM_ROLE ... FORMAT PARQUET MANIFEST;` then compare `COUNT(*)`; replay the `_ddl/` scripts.
- **EFS**: read the DataSync Task Report; confirm object count + bytes match; checksum a random sample on a helper.
- **EBS**: `aws s3 cp - | tar tzf -` lists cleanly; spot-extract known files; confirm all partitions present.
Set `restore_verified=true` + evidence per row.

---

## 9. Deletion gate + finish

- Set each manifest row `backed_up && integrity_verified && restore_verified` (or `skipped && skip_confirmed`). A named human records `gate.all_rows_satisfied`, `gate_approved_by`, `gate_approved_at`.
- Let the lifecycle rule transition artifacts to Glacier Instant Retrieval.
- Teardown: terminate helper instances, delete clone volumes + copied snapshots, delete scratch verify resources, delete the temporary RDS inbound rule. Leave the SOURCES untouched.
- Deleting the sources is a SEPARATE effort, allowed only after the gate is signed. That effort must first remove the section 1.5 protections. The root volumes then stay after instance termination (`Delete on termination: No`), so it must delete them explicitly.

---

### Console navigation validated 2026-09-14 (AWS Knowledge MCP)
Key current-UI facts: SSE-S3 is the S3 default (field just confirms it); `s3:DeleteObject*` is invalid policy syntax; IAM instance profiles are created only via the EC2 use-case role; DataSync **Basic mode** is required for "Verify all data" (Enhanced verifies only transferred files); Redshift cross-region UNLOAD needs `REGION 'eu-central-1'`; Session Manager needs `AmazonSSMManagedInstanceCore` on the instance profile; CloudShell `$HOME` is 1 GB (stream large data to S3 or use a helper EC2).
