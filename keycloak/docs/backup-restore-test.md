# Keycloak PostgreSQL backup and restore test

Related issue: https://github.com/Greenstand/treetracker-infrastructure/issues/160

## Purpose and scope

Verify that a PostgreSQL backup of the `keycloak` schema can be restored into a fresh database and used by a separate Keycloak instance.

This is a local Docker test using fictional accounts. It is not a production recovery procedure and does not access Greenstand infrastructure.

Tested on 2026-10-14:

- Windows PowerShell and Docker Desktop using Linux containers.

- Official Keycloak image `quay.io/keycloak/keycloak:23.0.0`.

- PostgreSQL image `postgres:14`.

- Database `treetracker`, schema `keycloak`, database role `s_keycloak`.

The repository Dockerfile references Keycloak 23.0. The actual deployed version and custom image were not verified. This test uses the official image without Greenstand themes or custom providers.

## Prerequisites

- Docker Desktop running Linux containers.

- PowerShell.

- Ports 8160 and 8161 available.

- No existing containers or network with the names used below.

Run commands individually. After each Docker command, check `$LASTEXITCODE`; stop if it is not zero. An empty command output does not by itself prove success.

All passwords below are public, fictional lab values. Never use them for a shared environment.

## 1. Create the source database

Keep the backup outside the Git checkout:

```powershell

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\greenstand-160-lab" | Out-Null

docker network create greenstand-160-lab

docker run -d --name greenstand-160-postgres --network greenstand-160-lab -e POSTGRES_USER=labadmin -e POSTGRES_PASSWORD=LocalLab160Only -e POSTGRES_DB=treetracker postgres:14

docker exec greenstand-160-postgres pg_isready -U labadmin -d treetracker

```

Wait for `accepting connections` before continuing.

Create the application role and schema:

```powershell

docker exec greenstand-160-postgres psql -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "CREATE ROLE s_keycloak LOGIN PASSWORD 'LocalKeycloak160Only'; CREATE SCHEMA keycloak AUTHORIZATION s_keycloak;"

```

## 2. Start the source Keycloak instance

```powershell

docker run -d --name greenstand-160-keycloak --network greenstand-160-lab -p 127.0.0.1:8160:8080 -e KC_DB=postgres -e KC_DB_URL_HOST=greenstand-160-postgres -e KC_DB_URL_DATABASE=treetracker -e KC_DB_SCHEMA=keycloak -e KC_DB_USERNAME=s_keycloak -e KC_DB_PASSWORD=LocalKeycloak160Only -e KEYCLOAK_ADMIN=labadmin -e KEYCLOAK_ADMIN_PASSWORD=LocalAdmin160Only quay.io/keycloak/keycloak:23.0.0 start-dev

docker logs --tail 60 greenstand-160-keycloak

```

Wait for the log message indicating that Keycloak started.

`start-dev` and HTTP are used only for this local laboratory. Both published ports are bound to loopback.

## 3. Create and verify test data

Open http://localhost:8160/admin/ and sign in:

- Username: `labadmin`

- Password: `LocalAdmin160Only`

Create an enabled realm named `backup-lab`.

In that realm, create an enabled user:

- Username: `restore-test`

- Email: `restore-test@example.com`

- First name: `Restore`

- Last name: `Test`

- Required user actions: empty.

Set a non-temporary password using the Credentials tab:

- Password: `LocalUser160Final!`

- Temporary: Off.

Open a fresh private browser session and sign in at:

http://localhost:8160/realms/backup-lab/account/

Confirm that the account page shows `Restore Test`.

Record the source user metadata:

```powershell

$labQuery = "SELECT r.name AS realm, u.id, u.username, u.email, (SELECT count(*) FROM keycloak.credential c WHERE c.user_id = u.id AND c.type = 'password') AS password_records FROM keycloak.user_entity u JOIN keycloak.realm r ON r.id = u.realm_id WHERE r.name = 'backup-lab' AND u.username = 'restore-test';"

docker exec greenstand-160-postgres psql -X -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "$labQuery"

```

Expect one user row with `password_records = 1`. This query does not display password hashes.

## 4. Back up the Keycloak schema

Stop the source Keycloak instance to prevent application writes during this test:

```powershell

docker stop greenstand-160-keycloak

```

Create a custom-format archive inside the PostgreSQL container:

```powershell

docker exec greenstand-160-postgres pg_dump -U labadmin -d treetracker --schema=keycloak --format=custom --no-owner --no-acl --file=/tmp/keycloak-160.dump

docker cp greenstand-160-postgres:/tmp/keycloak-160.dump "$env:USERPROFILE\greenstand-160-lab\keycloak-160.dump"

Get-Item "$env:USERPROFILE\greenstand-160-lab\keycloak-160.dump" | Select-Object Name, Length

```

The observed archive size was 212486 bytes. Size may differ on another run and is not proof that a backup is recoverable.

Using a container file and `docker cp` avoids passing a binary archive through PowerShell text redirection.

The archive contains sensitive Keycloak data, including credential records and realm keys. Custom format is not encryption. Do not commit the archive to Git.

## 5. Prepare a fresh restore database

```powershell

docker run -d --name greenstand-160-postgres-restored --network greenstand-160-lab -e POSTGRES_USER=labadmin -e POSTGRES_PASSWORD=LocalLab160Only -e POSTGRES_DB=treetracker postgres:14

docker exec greenstand-160-postgres-restored pg_isready -U labadmin -d treetracker

```

Wait for `accepting connections`.

Database roles are not included in `pg_dump`, so create the application role separately:

```powershell

docker exec greenstand-160-postgres-restored psql -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "CREATE ROLE s_keycloak LOGIN PASSWORD 'LocalKeycloak160Only';"

```

Do not create the schema manually: the archive includes its definition.

## 6. Restore the archive

```powershell

docker cp "$env:USERPROFILE\greenstand-160-lab\keycloak-160.dump" greenstand-160-postgres-restored:/tmp/keycloak-160.dump

docker exec greenstand-160-postgres-restored psql -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "GRANT CREATE ON DATABASE treetracker TO s_keycloak;"

docker exec greenstand-160-postgres-restored pg_restore -U labadmin -d treetracker --role=s_keycloak --no-owner --no-acl --exit-on-error --single-transaction /tmp/keycloak-160.dump

$LASTEXITCODE

```

Expect exit code `0`. Stop on failure; do not start Keycloak against an unsuccessful restore.

The restore runs as `s_keycloak`, so newly created objects belong to that role. Original ownership and ACLs are intentionally not restored in this isolated lab.

Remove the temporary database-level CREATE permission:

```powershell

docker exec greenstand-160-postgres-restored psql -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "REVOKE CREATE ON DATABASE treetracker FROM s_keycloak;"

```

## 7. Start Keycloak against the restored database

Use the same Keycloak version as the source:

```powershell

docker run -d --name greenstand-160-keycloak-restored --network greenstand-160-lab -p 127.0.0.1:8161:8080 -e KC_DB=postgres -e KC_DB_URL_HOST=greenstand-160-postgres-restored -e KC_DB_URL_DATABASE=treetracker -e KC_DB_SCHEMA=keycloak -e KC_DB_USERNAME=s_keycloak -e KC_DB_PASSWORD=LocalKeycloak160Only quay.io/keycloak/keycloak:23.0.0 start-dev

docker logs --tail 60 greenstand-160-keycloak-restored

```

Wait for successful startup.

No administrator bootstrap variables are supplied: the administrator must come from the restored data.

## 8. Verify recovery

Close all private browser windows, then open a new private session.

Visit http://localhost:8161/realms/backup-lab/account/ and sign in with:

- Username: `restore-test`

- Password: `LocalUser160Final!`

Confirm that a fresh password login succeeds and the account page shows `Restore Test`.

Also visit http://localhost:8161/admin/ and sign in with the original administrator credentials. Confirm that `backup-lab` and its `restore-test` user are visible.

Compare the restored user metadata with the source:

```powershell

docker exec greenstand-160-postgres-restored psql -X -U labadmin -d treetracker -v ON_ERROR_STOP=1 -c "$labQuery"

```

The realm, user ID, username, email, and password-record count must match the source.

## Observed results

On 2026-10-14:

- Source Keycloak startup and user login succeeded.

- Schema backup completed.

- Restore into a separate, fresh PostgreSQL container completed with exit code 0.

- Restored Keycloak started successfully without administrator bootstrap variables.

- Fresh user login succeeded with the password set before backup.

- Administrator login succeeded; the restored realm and user were visible.

- Source and restored user IDs, usernames, emails, realm names, and password-record counts matched.

These checks verify the tested account and administrator access. They do not constitute an exhaustive comparison of all database objects or application integrations.

## Limits and requirements before use in Greenstand

This test does not verify:

- Recovery of the actual development or production database.

- Greenstand's custom image, themes, providers, or external identity providers.

- Existing PostgreSQL ownership and ACL requirements.

- Cross-schema dependencies, extensions, or objects outside `keycloak`.

- Recovery across different Keycloak or PostgreSQL versions.

- Persistence of active sessions, recovery time objectives, or point-in-time recovery.

Before adapting the procedure, maintainers should confirm the deployed versions, schema, dependencies, required roles and grants, and application configuration.

A schema-only dump does not automatically include dependencies outside that schema. A separate production procedure must account for them and preserve the intended ownership and permissions.

Production backups also require protected storage, encryption, retention, and recurring restore verification. The database archive does not replace backups of deployment configuration, custom providers, themes, or external secrets.

## Local cleanup

After verification, remove only this lab's containers and their anonymous volumes:

```powershell

docker rm -f -v greenstand-160-keycloak greenstand-160-keycloak-restored greenstand-160-postgres greenstand-160-postgres-restored

docker network rm greenstand-160-lab

```

When the fictional backup is no longer needed:

```powershell

Remove-Item "$env:USERPROFILE\greenstand-160-lab\keycloak-160.dump"

```

Do not use broad Docker pruning commands as part of this cleanup.

## References

- PostgreSQL 14 pg_dump: https://www.postgresql.org/docs/14/app-pgdump.html

- PostgreSQL 14 pg_restore: https://www.postgresql.org/docs/14/app-pgrestore.html
