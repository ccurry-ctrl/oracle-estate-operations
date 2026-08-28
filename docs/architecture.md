# Architecture

## Purpose

`oracle-estate-operations` is a public-safe reference implementation for operating a fictional enterprise Oracle database estate.

The project is intended to demonstrate an operational engineering pattern:

1. define a supportable standard;
2. collect and normalize operational data;
3. expose useful state and exceptions;
4. automate repetitive validation and maintenance;
5. document the remaining operator actions;
6. preserve justified exceptions instead of forcing uniformity for its own sake.

The repository must remain fictional and sanitized. It must not contain employer code, configuration, hostnames, credentials, application names, or proprietary operating procedures.

## V1 Scope

V1 models approximately 20 fictional Oracle PDBs supporting several fictional applications.

The estate will include:

- single-instance and RAC CDBs;
- multiple PDBs within CDBs;
- RAC instance and node topology as supporting infrastructure detail;
- primary and standby Data Guard roles;
- multiple application owners and support contacts;
- expected database services and instance placement;
- patch groups and maintenance schedules;
- account/schema and service metadata;
- one documented exception to the normal estate standard.

## Inventory Grain

The primary operational inventory is **PDB-grain**: one row per PDB.

A DBA, application owner, or support engineer should be able to begin with the PDB and answer the common operational questions without first reasoning through infrastructure topology.

CDB, RAC instance, cluster, and node data enrich that inventory but do not change its grain.

```text
DB_CLUSTER
   |
   +-- CDB: ABC
         |
         +-- DB_INSTANCE: ABC1 -> node01
         +-- DB_INSTANCE: ABC2 -> node02
         +-- DB_INSTANCE: ABC3 -> node03
         +-- DB_INSTANCE: ABC4 -> node04
         |
         +-- PDB: P001   <- main inventory row
         +-- PDB: P002   <- main inventory row
         +-- PDB: P003   <- main inventory row
         +-- PDB: P004   <- main inventory row
```

`V_ESTATE_STATUS` must therefore return exactly one row per PDB. Infrastructure reporting uses supporting views such as `V_CDB_INSTANCE_STATUS` so one-to-many RAC instance data cannot duplicate rows in the main inventory.

## Architecture

```text
                  Fictional estate metadata
                           |
                    Oracle Database
                           |
          +----------------+----------------+
          |                                 |
  Operational views                  Compliance views
          |                                 |
          +----------------+----------------+
                           |
                  +--------+--------+
                  |                 |
             Oracle APEX       CLI / scripts
                  |
          Operations portal
```

## Oracle Layer

Oracle is the system of record for the lab.

Initial tables model:

- projects and operational ownership;
- environments;
- clusters and nodes;
- CDBs;
- RAC instances and their node placement;
- PDBs as the primary inventory objects;
- services and expected instance placement;
- Data Guard relationships at the CDB level;
- account/schema ownership at the PDB level;
- patch groups and CDB maintenance schedules;
- documented PDB or CDB standard exceptions.

Views separate stored metadata from operational questions. Initial views include:

- PDB estate status/main inventory;
- CDB and RAC instance topology;
- PDB and account ownership;
- service compliance;
- patch readiness/calendar;
- DR status;
- standards exceptions.

APEX and CLI tooling should consume these views rather than duplicating business rules in multiple interfaces.

## APEX Layer

APEX is the human-facing operations portal, not the source of operational logic.

Initial pages:

1. **Estate Overview** - one row per PDB with application, ownership, environment, CDB, cluster, status, and operational context.
2. **Database Detail** - PDB detail with its parent CDB and drill-down access to RAC instance/node topology, services, ownership, accounts, DR, and patch information.
3. **Service Compliance** - expected service placement compared with observed RAC instance placement.
4. **Patch Schedule** - planned RU maintenance by CDB/application/environment and completion state.

The application should remain intentionally small. The goal is to demonstrate useful operational visibility, not build a complete enterprise monitoring product.

## Automation Layer

V1 will include one command-line validation workflow that reports whether the fictional estate conforms to the same standards represented in Oracle views and APEX.

Automation should be introduced only where it removes repeatable operator work. Procedures should exist before automation when documenting the manual process helps clarify inputs, outputs, guardrails, and failure handling.

## Documentation Model

Top-level runbooks orchestrate a task. Reusable actions live under `docs/runbooks/procedures/`.

A procedure should be independently reusable and should include explicit prerequisites, commands/actions, validation, STOP conditions, failure handling, and completion criteria.

A top-level runbook should link to those procedures rather than duplicate them.

## V1 Non-Goals

The following are intentionally deferred:

- Terraform provisioning;
- Ansible configuration management;
- CI/CD pipelines;
- enterprise authentication or SSO;
- live OEM repository integration;
- production-grade observability;
- simulation of an entire enterprise Oracle estate;
- employer-specific processes or code.

These may be added later when they demonstrate a real engineering progression rather than portfolio decoration.
