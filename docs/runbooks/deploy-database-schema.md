# Deploy Database Schema with SQLcl

## Purpose

Deploy and validate the Oracle Estate Operations database layer from the SQL stored in this repository.

The SQL files are the source of truth. Do not repair a failed deployment by creating objects manually in APEX SQL Workshop or by making undocumented changes directly in the database.

## Prerequisites

Before starting, confirm:

- the repository is cloned to the operator workstation;
- SQLcl is installed and working;
- the lab Oracle database is healthy;
- the workstation can reach the database listener;
- administrative database credentials are available to the operator and are not stored in Git;
- you know which lab database you are connected to.

The documented lab uses Oracle Autonomous AI Database Free 26ai, but this procedure is about the project schemas rather than the container itself. See [Oracle Container Deployment](procedures/oracle-container-deploy.md) if the database platform has not been built yet.

## Security guardrails

- Never commit schema passwords, ADMIN passwords, wallet passwords, or generated credential files.
- `ESTATE` owns the base data model.
- `ESTATE_AO` owns the curated application-facing objects.
- `APPESTATE` is the runtime/APEX parsing identity.
- `APPESTATE` must not receive direct access to `ESTATE` tables just to make an application error disappear.
- Deployment stops on SQL errors.

## 1. Confirm the target

Connect to the intended lab database with SQLcl using your local Oracle client configuration.

How the client connection is configured depends on the Oracle platform and workstation. Keep wallets, TNS configuration, and credentials outside this repository.

Before running any DDL, verify the database you reached. Do not infer the target from shell history or a saved terminal tab.

**PASS:** You can identify the target as the disposable lab database and the connection has the privileges required to create the project schemas.

**STOP:** Do not continue if the target is uncertain or is not safe for this lab deployment.

## 2. Install the database objects

From the repository root while connected through SQLcl, run:

```sql
@deploy/install.sql
```

The installer prompts for passwords for:

- `ESTATE`;
- `ESTATE_AO`;
- `APPESTATE`.

Input is hidden and the passwords are not written to the repository.

The install creates:

- the three schemas;
- the `ESTATE` base tables and constraints;
- the grants required by the App Objects layer;
- the `ESTATE_AO` operational views;
- the runtime grants to `APPESTATE`.

The installer is a create/install path, not a reset path. Re-running it against an existing installation can fail at schema creation. That is preferable to silently destroying an existing database.

**PASS:** `deploy/install.sql` reaches the installation-complete prompt without SQL errors.

**STOP:** Stop on any DDL or grant failure. Do not create the missing object by hand and continue.

## 3. Load the fictional estate

Run:

```sql
@deploy/seed.sql
```

This loads two intentionally separate layers:

1. `01_reference_topology.sql` creates the fictional projects, environments, RAC topology, CDBs, PDB occurrences, ownership mappings, and Data Guard relationships.
2. `02_operational_state.sql` adds the mutable conditions used by reporting and validation.

Keeping topology separate from operating state makes it possible to understand whether a change describes what the estate *is* or what is *currently happening* in it.

**PASS:** Both seed scripts complete without SQL errors.

**STOP:** Do not repair a seed failure with manual inserts or updates. Correct the source SQL or the prerequisite that caused the failure.

## 4. Validate

Run:

```sql
@deploy/validate.sql
```

Review the output. Validation checks include:

- schema and object status;
- one main-inventory row per PDB occurrence on each `DB_UNIQUE_NAME`;
- one primary project mapping per PDB occurrence;
- RAC instance topology;
- the `ESTATE` to `ESTATE_AO` grant boundary;
- the `ESTATE_AO` to `APPESTATE` runtime boundary;
- service-placement mismatches;
- deferred patch state;
- Data Guard health;
- active standards exceptions;
- cross-project account ownership.

Some sections return no rows when healthy. Others intentionally return the seeded non-green conditions. Read the expected-result prompts rather than treating the final line of the script as the only success signal.

The runtime privilege model should resolve to:

```text
ESTATE
  base data owner
      |
      | READ WITH GRANT OPTION
      v
ESTATE_AO
  curated application-facing views
      |
      | READ
      v
APPESTATE
  runtime / APEX identity
```

**PASS:** Required objects are valid, the privilege boundary matches [Security Model](../security-model.md), inventory grain is correct, and only the documented intentional operating conditions appear.

**STOP:** Treat an unexplained invalid object, privilege, relationship, or operating result as a failed deployment.

## Failure handling

If a step fails:

1. stop at the failed step;
2. capture the relevant non-secret SQLcl output;
3. determine whether the problem is the database platform, client connection, deployment SQL, or seed data;
4. fix the responsible source or prerequisite;
5. repeat the failed step from a known state.

Do not add a generic destructive reset to normal deployment just to make retries convenient. If the disposable lab needs a clean rebuild, make that teardown deliberate.

## Completion criteria

The database deployment is complete when:

- `ESTATE`, `ESTATE_AO`, and `APPESTATE` are present and usable;
- the base model and eight operational views are valid;
- the fictional topology and operational scenarios are loaded;
- `APPESTATE` remains limited to the documented runtime interface;
- `deploy/validate.sql` produces the expected structural and operational results;
- another qualified operator can reproduce the deployment from the repository without undocumented database changes.
