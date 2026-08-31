# Architecture

## Purpose

This document describes the current V1 architecture for `oracle-estate-operations`.

The project follows the same operating pattern used in the README:

1. define a supportable standard;
2. model the estate around the questions operators actually need to answer;
3. expose state and exceptions through shared database views;
4. automate repeatable validation;
5. document the remaining operator work;
6. preserve justified exceptions instead of forcing uniformity for its own sake.

The repository is fictional and sanitized. It does not contain employer code, configuration, hostnames, credentials, application names, or proprietary operating procedures.

## Current V1 Scope

The V1 seed estate models five fictional applications across development, QA, test, UAT, and production. It includes:

- single-instance and RAC CDBs;
- multiple PDBs within CDBs;
- East/West Data Guard peers for production-like environments;
- RAC instance and node topology;
- application and support ownership;
- database services with expected and observed placement;
- patch groups and CDB maintenance schedules;
- account/schema ownership;
- documented standards exceptions;
- intentionally seeded operational faults for validation.

The current seed topology contains seven CDB occurrences and 40 PDB occurrences.

## Inventory Grain

The primary operational inventory is **one PDB occurrence per `DB_UNIQUE_NAME`**.

That distinction matters for Data Guard. A logical PDB may exist on both a primary and standby peer, and both occurrences belong in operational inventory because they represent two different physical database targets.

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

`V_ESTATE_STATUS` therefore returns one row per PDB occurrence on a `DB_UNIQUE_NAME`. One-to-many RAC instance detail is kept in supporting views such as `V_CDB_INSTANCE_STATUS` so it cannot duplicate rows in the main inventory.

## Architecture

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

Oracle is the system of record for the lab. The important design choice is that APEX and command-line tooling consume the same database views instead of each rebuilding joins and operating rules independently.

## Data Owner Layer

`ESTATE` owns the base model. The implemented tables cover:

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

The model keeps application identity, infrastructure placement, and current operational state separate where they can change independently.

## App Objects Layer

`ESTATE_AO` owns the curated operational interface. V1 currently exposes:

- `V_ESTATE_STATUS`
- `V_CDB_INSTANCE_STATUS`
- `V_PDB_OWNERSHIP`
- `V_ACCOUNT_OWNERSHIP`
- `V_SERVICE_COMPLIANCE`
- `V_PATCH_READINESS`
- `V_DR_STATUS`
- `V_ACTIVE_EXCEPTIONS`

These views are the contract presented to APEX and validation tooling. Base-table structure can evolve without forcing every consumer to know how the underlying joins work.

## APEX Layer

APEX is the human-facing operations interface, not the source of operational logic.

The current V1 application contains an **Estate Overview** faceted search backed directly by `ESTATE_AO.V_ESTATE_STATUS`.

Additional pages such as service compliance, patch readiness, Data Guard status, or exception review are reasonable next steps because the backing views already exist, but they are not required for the current V1 to prove the pattern.

The UI stays intentionally small. I would rather add a page because an operator needs it than because another page makes the portfolio look more complete.

## Validation Layer

`deploy/validate.sql` checks both structure and operating state. Current checks include:

- schema and object validity;
- PDB inventory grain;
- primary project uniqueness;
- runtime privilege boundaries;
- service placement mismatches;
- deferred patch schedules;
- unhealthy Data Guard state;
- active standards exceptions;
- cross-project account ownership.

Some of those checks are expected to return seeded findings. The goal is to verify that the model can represent and surface a problem, not to make every result green.

## Documentation Model

Top-level runbooks describe a complete operator task. Reusable actions live under `docs/runbooks/procedures/` so the same procedure can be called from more than one runbook without maintaining duplicate instructions.

A reusable procedure should include prerequisites, actions, validation, stop conditions, failure handling, and completion criteria. If a task is automated later, the procedure still documents the inputs, expected result, and recovery path.

## V1 Boundaries

V1 intentionally stops before Terraform provisioning, Ansible configuration management, CI/CD, enterprise SSO, live OEM integration, and production-grade observability.

Those are all reasonable technologies in a larger platform. They are deferred here because the current problem does not require them. New components should be added when they remove real operator work, improve control, or make the estate easier to support.
