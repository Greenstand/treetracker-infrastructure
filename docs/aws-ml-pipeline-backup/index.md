# AWS ML pipeline backup and cleanup - volunteer guide

This guide explains, in plain language, how we save the data from an old, unused part of our AWS account before we delete it. It is written for volunteers. You do not need to be an AWS expert to follow it. A short glossary at the end explains every technical word.

- **Detailed engineer steps:** [runbook.md](runbook.md)
- **Same steps as clicks in the AWS web console:** [console-runbook.md](console-runbook.md)
- **Safety reference (how backups can silently fail, and how we stop that):** [data-loss-risk-register.md](data-loss-risk-register.md)

This is a **plan**. It has not run yet. Running it is a separate task that needs a person with write access to the AWS account.

## 1. What this is

Our AWS account holds an old machine-learning system. The system was used to label tree images and train models. Nobody has used it for about 15 months. It still runs, so it still costs money every month.

We want to **delete** this old system to save money. But first we must **make a safe copy** of any real data it holds. This guide is that backup plan.

## 2. Why we do it

Two reasons:

1. **Save money.** The old system costs about 500 US dollars each month for nothing. Deleting it saves roughly 350 to 425 US dollars each month.
2. **Lose nothing.** Some of the old parts may still hold useful data, for example past tree-image datasets. We copy that data to safe, cheap storage before we delete anything. If someone needs it later, we still have it.

The rule is simple: **back up first, check the backup works, then delete.**

## 3. What we back up

We looked at every part of the old system. In total there is about half a terabyte of data across five AWS regions. We back up **18 items**. We skip nothing without a check.

| Type | What it is | How many | Notes |
|------|-----------|----------|-------|
| Databases (RDS) | Two PostgreSQL databases | 2 | One is small and idle; one is 1.67 GB and open to the internet |
| Data warehouse (Redshift) | One serverless data warehouse | 1 | About 0.85 GB |
| Disks (EBS) | Hard-disk volumes from old servers | 4 firm + 2 to check | The 2 "to check" have been unused since 2021 |
| File systems (EFS) | Shared folders from the old ML workspace | 3 with data + 6 empty | The 6 empty ones are copied anyway, to be safe |

We do **not** back up: the live Treetracker product data, the machine-learning files that already sit safely in S3, and system settings that can be recreated.

## 4. Where the backup goes

All backups go into **one new S3 bucket** (a bucket is a storage folder in AWS):

- **Name:** a dedicated bucket created just for this archive
- **Region:** Europe (Frankfurt)
- **Cost class:** Glacier Instant Retrieval. This is cheap, long-term storage. You can still read it right away when you need it.
- **How long we keep it:** forever, unless we decide otherwise later.
- **Protection:** the bucket blocks public access, blocks accidental deletion with a policy, and forces secure (HTTPS) connections.

We save the data as **normal files** (for example a database dump file, or a compressed folder). This means the files do not depend on the old AWS service. We can restore them anywhere.

## 5. The golden safety rule

We never delete anything from AWS until **all** of these are true for that item, written down in a tracking file called the **manifest**:

1. **Backed up:** the file is in the archive bucket.
2. **Integrity checked:** the file's checksum (a digital fingerprint) matches, so we know it is not damaged.
3. **Restore tested:** we actually opened the backup and confirmed the data is usable.

Only when every one of the 18 items passes all three checks, and a named person signs off, may the delete work begin. The backup bucket has no version history, so the manifest and the restore test are our main safety net. Treat them as required, not optional.

## 6. How the backup works, part by part

Each part uses the safest standard AWS method. Full commands are in the [runbook](runbook.md); click-by-click console steps are in the [console runbook](console-runbook.md).

- **Databases (RDS):** we use `pg_dump` to make a single restorable dump file, then upload it. We do not use the AWS "export to S3" feature, because that format cannot be loaded back into a database.
- **Data warehouse (Redshift):** we use the `UNLOAD` command to write every table to the bucket as Parquet files. We also save the table definitions, because `UNLOAD` saves only the rows, not the structure.
- **File systems (EFS):** we use AWS DataSync, a managed copy service, in "Basic mode" so it can fully verify every file after the copy.
- **Disks (EBS):** we take a snapshot, make a copy volume, attach it to a small helper server, and copy the whole file system to a compressed file. We check every disk partition so we miss nothing.

For the 2 disks unused since 2021, we cannot see inside them yet, because the current login is read-only. A person with write access must attach and inspect them first, then decide to back up or skip.

## 7. What it costs

- **To keep the backup:** about 1 to 3 US dollars each month.
- **To run the backup once:** about 15 to 40 US dollars, one time.

This is very small next to the 350 to 425 US dollars each month that the cleanup will save.

## 8. Who does what

- **A person with AWS admin access** must first create the bucket and the security roles (the current login cannot). This is the one-time setup.
- **After setup**, the backup steps can run, either by a person or by an automated agent that holds the correct role.
- **Deleting the old system** is a separate, later task. It starts only after the manifest sign-off.

If you want to help, read the [console runbook](console-runbook.md). It shows every step as a click in the AWS web console, and marks which steps need a browser terminal.

## 9. Glossary

- **AWS:** Amazon Web Services, the cloud provider we use.
- **Region:** a geographic location where AWS stores data, for example Europe (Frankfurt) or US East.
- **S3:** AWS object storage. It holds files in "buckets".
- **Bucket:** a top-level storage folder in S3.
- **Glacier Instant Retrieval:** a low-cost S3 storage class for data you rarely use but may need quickly.
- **RDS:** AWS Relational Database Service, a managed SQL database.
- **PostgreSQL:** the database software our RDS databases use.
- **pg_dump:** a standard tool that copies a PostgreSQL database into one file.
- **Redshift:** AWS data-warehouse service, used for large analysis queries.
- **UNLOAD:** a Redshift command that writes query results to S3 files.
- **Parquet:** a compact, self-describing file format for table data.
- **EBS:** AWS Elastic Block Store, the virtual hard disks attached to servers.
- **Snapshot:** a point-in-time copy of an EBS disk.
- **EFS:** AWS Elastic File System, a shared network folder.
- **DataSync:** an AWS service that copies files between storage systems and verifies them.
- **Checksum:** a short digital fingerprint used to confirm a file is not damaged.
- **Manifest:** our tracking file that records the status of every backup item.
- **Restore test:** opening a backup to confirm the data is usable.
- **CloudShell / Session Manager:** browser terminals inside the AWS console, used for steps that need typed commands.
