# Deploy Database Schema with SQLcl

## Purpose

Deploy the Oracle Estate Operations database foundation from Git-managed SQL using Oracle SQLcl.

This runbook is the orchestration layer. SQL files in `sql/` remain the source of truth for database objects.

## Prerequisites

- Oracle Estate Operations repository cloned to the operator workstation.
- Oracle SQLcl installed on the operator workstation.
- Network connectivity from the workstation to the lab Oracle listener.
- Administrative database credentials available to the operator but not stored in Git.
- ADB Free 26ai lab container healthy.
- Review the SQL implementation branch before execution.

## Security Guardrails

- Never commit schema passwords, ADMIN passwords, wallet passwords, or generated credential files.
- `ESTATE` owns stored application data.
- `ESTATE_AO` means App Objects and owns application-facing views and related objects.
- `APPESTATE` is the runtime/APEX parsing identity and should not own core objects.
- `APPESTATE` must not receive direct access to `ESTATE` tables merely to resolve an application error.
- Deployment must stop on SQL errors.

## Procedure

### 1. Confirm the target

Before deployment, verify that the SQLcl connection points to the intended lab database. Do not infer the target from shell history.

### 2. Review pending SQL

Review the implementation branch and confirm that the deployment contains only the expected schema, table, grant, view, and validation changes.

### 3. Connect with SQLcl

Connect to the lab database using the appropriate ADB Free service and administrative credentials.

The exact connection form depends on the generated wallet/TNS configuration and will be documented after the first workstation connection is validated.

### 4. Run the master installer

From the repository root while connected through SQLcl:

```text
@deploy/install.sql
```

SQLcl prompts for the three schema passwords with hidden input. Passwords are not stored in the repository.

### 5. Validate

Run:

```text
@deploy/validate.sql
```

Expected results:

- `ESTATE`, `ESTATE_AO`, and `APPESTATE` exist and are open;
- ESTATE tables are valid;
- ESTATE_AO views are valid;
- APPESTATE has `CREATE SESSION` and no unnecessary system privileges;
- APPESTATE has no direct grants on ESTATE tables;
- APPESTATE has SELECT access to the approved ESTATE_AO views;
- no invalid project objects remain.

## PASS

Deployment passes when all three schemas exist, project objects are valid, and the runtime privilege boundary matches `docs/security-model.md`.

## STOP

Stop the deployment when:

- SQLcl is connected to an unexpected database;
- any password or credential would be written to Git;
- a DDL statement fails;
- APPESTATE requires broad privileges or direct ESTATE table access to make the deployment succeed;
- validation reports unexpected or invalid objects.

Do not continue by manually creating missing objects in APEX SQL Workshop. Fix the Git-managed SQL and redeploy from the documented path.

## Failure Handling

V1 does not yet provide an automated destructive rollback because schema removal would destroy data. During the disposable initial lab build, a failed first deployment may be reset deliberately after the failure is understood.

Do not add a generic `DROP USER ... CASCADE` operation to normal deployment automation.

## Completion Criteria

The procedure is complete when the Git-managed database foundation is reproducibly deployed with SQLcl and validation demonstrates the intended three-schema security boundary.
