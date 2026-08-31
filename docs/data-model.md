# V1 Data Model

## Purpose

This document describes the implemented V1 data model for the fictional Oracle estate.

The model is centered on the questions an operator needs to answer, not just on listing databases. Application identity, environment, infrastructure placement, ownership, and current operating state are related, but they are not the same thing and should not be collapsed into one record or naming convention.

The working rule is:

> Where an object lives does not necessarily determine who owns it.

That applies to PDBs, accounts, services, and the application relationships around them.

## Inventory Grain

The main inventory grain is **one PDB occurrence per `DB_UNIQUE_NAME`**.

A logical PDB can appear more than once when it exists on separate Data Guard peers. For example:

```text
Project  PDB   Environment  DB_UNIQUE_NAME  Role
001      P001  PROD         PHR001E         PRIMARY
001      P001  PROD         PHR001W         STANDBY
```

Those are two operational targets, not duplicate rows.

RAC instances and cluster nodes are supporting infrastructure beneath the CDB. A PDB is not assigned to one RAC instance. Service placement is modeled separately because services are what express where workload is expected to run.

## Core Relationships

```text
PROJECT
   |
   +---- PDB_PROJECT ---- PDB ---- CDB ---- DB_CLUSTER
   |                       |         |           |
   |                       |         |           +---- CLUSTER_NODE
   |                       |         |                    |
   |                       |         +---- DB_INSTANCE ----+
   |                       |
   |                       +---- DB_ACCOUNT ---- ACCOUNT_PROJECT ---- PROJECT
   |                       |
   |                       +---- DB_SERVICE ---- SERVICE_INSTANCE_EXPECTATION ---- DB_INSTANCE
   |
CDB ---- DR_RELATIONSHIP ---- CDB
 |
 +---- CDB_PATCH_SCHEDULE ---- PATCH_GROUP
 |
 +---- STANDARD_EXCEPTION

PDB ---- STANDARD_EXCEPTION
```

## Business and Ownership Model

### `PROJECT`

`PROJECT` is the reusable application/ownership anchor. It holds the project code, application name, description, owner, SME, manager, support URL, and active state.

The point is to maintain application ownership once and associate it with the PDBs and accounts that belong to it instead of repeating the same contact information across inventory rows.

### `PDB_PROJECT`

`PDB_PROJECT` maps PDB occurrences to projects. A PDB can have multiple project relationships, but V1 allows only one relationship to be marked primary for the main inventory.

This gives the Estate Overview a clear default application while preserving the ability to represent shared or secondary relationships.

### `DB_ACCOUNT` and `ACCOUNT_PROJECT`

Accounts are modeled at PDB level and have their own project relationship.

That is intentional. An integration schema or service account can live in one application's PDB while belonging to another project. The model does not infer account ownership from PDB ownership.

## Oracle Infrastructure Model

### `ENVIRONMENT`

`ENVIRONMENT` stores the workload lifecycle classification independently from database naming. V1 includes values such as DEV, QA, TEST, UAT, PERF, PROD, and DR as required by the seed model.

### `DB_CLUSTER` and `CLUSTER_NODE`

These tables model the hosting cluster and its nodes. They provide infrastructure context without changing the grain of the main PDB inventory.

### `CDB`

`CDB` represents a physical Oracle database identified by `DB_UNIQUE_NAME`.

It stores:

- Oracle `DB_NAME` as `CDB_NAME`;
- `DB_UNIQUE_NAME` as the physical database identity;
- single-instance or RAC architecture;
- current database role;
- Oracle version;
- cluster association;
- active state.

Data Guard role is stored as state rather than encoded into the name because PRIMARY and STANDBY can change after a switchover or failover.

### `DB_INSTANCE`

`DB_INSTANCE` maps a CDB's instances to cluster nodes. It captures instance name, instance number, status, and active state.

Keeping this one-to-many topology separate prevents RAC instance rows from multiplying the PDB-level main inventory.

### `PDB`

`PDB` is the primary business-facing database object in the model. Each row belongs to one CDB occurrence and one environment and stores its name, open mode, description, and active state.

Because the same logical PDB can exist on multiple Data Guard peers, PDB name is unique within a CDB rather than globally.

## Service Placement

### `DB_SERVICE`

`DB_SERVICE` defines an Oracle service for a PDB.

### `SERVICE_INSTANCE_EXPECTATION`

This table keeps expected and observed service placement side by side for each RAC instance.

That lets `V_SERVICE_COMPLIANCE` derive status instead of storing a hand-maintained compliance flag:

```text
EXPECTED  OBSERVED  RESULT
Y         Y         COMPLIANT
N         N         COMPLIANT
Y         N         MISMATCH
N         Y         MISMATCH
```

The model can therefore answer both **where should this service run?** and **where is it currently observed?**

## Data Guard

### `DR_RELATIONSHIP`

Data Guard relationships are modeled at CDB level because role, transport, and apply state belong to the physical database pair rather than to one individual PDB.

The relationship stores:

- primary CDB;
- standby CDB;
- protection mode;
- transport status;
- apply status.

`V_DR_STATUS` presents that state in operator-friendly form.

## Patching

### `PATCH_GROUP`

A patch group defines a target RU and maintenance window.

### `CDB_PATCH_SCHEDULE`

CDBs are scheduled into patch groups with scheduled date, completion date, and status. Patching is modeled at CDB level because RU lifecycle state belongs to the database infrastructure, while application impact is reached through the CDB-to-PDB relationships.

## Exceptions

### `STANDARD_EXCEPTION`

Exceptions are stored as data rather than buried in notes or tribal knowledge.

An exception can target a PDB or CDB and records:

- exception type;
- description;
- justification;
- approver;
- review date;
- active state.

An exception is not automatically a failure. A justified, documented deviation can still be inside the operating model even though it differs from the default standard.

## App-Facing Views

`ESTATE_AO` currently exposes eight views:

- `V_ESTATE_STATUS` - main PDB-grain inventory;
- `V_CDB_INSTANCE_STATUS` - CDB, RAC instance, and node topology;
- `V_PDB_OWNERSHIP` - PDB-to-project ownership;
- `V_ACCOUNT_OWNERSHIP` - account ownership independent of PDB ownership;
- `V_SERVICE_COMPLIANCE` - expected versus observed service placement;
- `V_PATCH_READINESS` - CDB patch schedule and RU state;
- `V_DR_STATUS` - Data Guard relationship state;
- `V_ACTIVE_EXCEPTIONS` - active PDB/CDB standards exceptions.

These views are the application contract. APEX and validation tooling consume them instead of rebuilding the underlying joins independently.

## Design Choices Kept Deliberate

A few things are intentionally not normalized further in V1.

Owner, SME, and manager remain attributes on `PROJECT` rather than introducing a separate person/contact model. That is enough for the current use case and keeps the project understandable. A contact model can be added if a real requirement appears for reusable people, multiple responsibility types, or directory integration.

Likewise, V1 does not add capacity history, OEM metric ingestion, ticketing integration, generalized cloud-resource inventory, or audit-event history. Those are reasonable additions only when there is an operating question that needs them.
