# Architecture

## Purpose

This document describes the V1 architecture for `oracle-estate-operations`.

The project follows a simple operating pattern:

1. define a supportable standard;
2. model the estate around the questions operators need to answer;
3. expose state and exceptions through shared database views;
4. automate repeatable deployment and validation;
5. document the remaining operator work;
6. preserve justified exceptions instead of forcing uniformity for its own sake.

The repository is fictional and sanitized. It contains no employer code, configuration, hostnames, credentials, application names, or proprietary operating procedures.

## V1 scope

The seed estate models five fictional applications across development, QA, test, UAT, and production. It includes:

- RAC CDBs and multiple PDBs;
- East/West Data Guard peers for production-like environments;
- RAC instance and node topology;
- application and support ownership;
- database services with expected and observed placement;
- patch groups and CDB maintenance schedules;
- account/schema ownership;
- documented standards exceptions;
- intentionally seeded operational faults for validation.

The topology contains four RAC clusters, seven CDB occurrences, 40 PDB occurrences, and three Data Guard relationships.

## Runtime layout

The public deployment path separates the operator workstation from the disposable Oracle runtime host:

```text
Operator workstation
Windows / macOS / Linux
Git / SQLcl / browser
        |
        v
Ubuntu Server LTS
        |
        v
Docker
        |
        v
Oracle ADB Free
Database + ORDS/APEX
```

The Linux host does not need the project repository, Git, SQLcl, or the operator's Oracle wallet. Those remain on the workstation. The host provides the container runtime, storage, and network endpoint.

## Inventory grain

The primary operational inventory is **one PDB occurrence per `DB_UNIQUE_NAME`**.

That distinction matters for Data Guard. A logical PDB may exist on both a primary and standby peer, and both occurrences belong in operational inventory because they are different physical database targets.

A DBA or application owner should be able to begin with the PDB and answer the common questions first:

- What application is this?
- Which environment is it?
- Where is it hosted?
- What role is the database performing?
- Who owns and supports it?

CDB, RAC instance, cluster, and node information provide infrastructure detail without changing the inventory grain.

```text
DB_CLUSTER
   |
   +-- CDB / DB_UNIQUE_NAME
         |
         +-- DB_INSTANCE -> cluster node
         |
         +-- PDB occurrence -> environment -> project/application
```

`V_ESTATE_STATUS` returns one row per PDB occurrence on a `DB_UNIQUE_NAME`. One-to-many RAC instance detail stays in supporting views such as `V_CDB_INSTANCE_STATUS` so it cannot duplicate rows in the main inventory.

## Database boundary

```text
                         ESTATE
                  DBA-managed data owner
                         |
              READ WITH GRANT OPTION
                         v
                      ESTATE_AO
             curated app-facing objects
                         |
                       READ
                         v
                      APPESTATE
              APEX / runtime identity
                         |
              +----------+----------+
              |                     |
         Oracle APEX           CLI / validation
```

Oracle is the system of record for the lab. APEX and command-line tooling consume the same database views instead of each rebuilding joins and operating rules independently.

### `ESTATE`

`ESTATE` owns the base model for:

- projects and operational ownership;
- environments;
- clusters and nodes;
- CDBs and RAC instances;
- PDB occurrences;
- PDB-to-project relationships;
- accounts and account ownership;
- services and expected/observed RAC placement;
- Data Guard relationships;
- patch groups and CDB schedules;
- standards exceptions.

Application identity, infrastructure placement, and current operating state remain separate where they can change independently.

### `ESTATE_AO`

`ESTATE_AO` owns the curated operational interface:

- `V_ESTATE_STATUS`
- `V_CDB_INSTANCE_STATUS`
- `V_PDB_OWNERSHIP`
- `V_ACCOUNT_OWNERSHIP`
- `V_SERVICE_COMPLIANCE`
- `V_PATCH_READINESS`
- `V_DR_STATUS`
- `V_ACTIVE_EXCEPTIONS`

These views are the contract presented to APEX and validation tooling. Consumers do not need to know the joins behind the base model.

### `APPESTATE`

`APPESTATE` is the least-privilege runtime identity used by APEX. It receives `READ` only on the approved `ESTATE_AO` views and no direct access to `ESTATE` tables.

See [Security Model](security-model.md) for the complete privilege boundary.

## APEX layer

APEX is a human-facing operations interface, not the source of operational logic.

The V1 application contains an **Estate Overview** faceted search backed directly by `ESTATE_AO.V_ESTATE_STATUS`. The public repository includes screenshots of that page but does not include an APEX application export.

Additional interfaces can consume the existing service, patch, DR, and exception views when an operator need justifies them. They are not part of V1.

## Deployment and validation

The database deployment path is deliberately explicit:

```text
deploy/install.sql
        |
        v
deploy/seed.sql
        |
        v
deploy/validate.sql
```

`install.sql` creates the schema and privilege boundary. `seed.sql` loads the reference topology and operational scenarios. `validate.sql` checks both structure and operating state.

Current validation covers:

- schema and object validity;
- PDB inventory grain;
- primary project uniqueness;
- runtime privilege boundaries;
- service placement mismatches;
- deferred patch schedules;
- unhealthy Data Guard state;
- active standards exceptions;
- cross-project account ownership.

Some findings are intentionally seeded. The goal is to prove that the model can represent and surface a problem, not to make every result green.

## Documentation model

Top-level runbooks describe a complete operator task. Reusable actions live under `docs/runbooks/procedures/` when the same procedure belongs to more than one task.

A procedure should make prerequisites, actions, validation, stop conditions, failure handling, and completion clear enough that another qualified operator can follow it without knowing how the original lab was built.

## V1 boundaries

V1 stops before Terraform provisioning, Ansible configuration management, CI/CD, enterprise SSO, live OEM integration, production-grade observability, and a deployable APEX export.

Those components belong here only when they remove real operator work, improve control, or make the estate easier to support.
