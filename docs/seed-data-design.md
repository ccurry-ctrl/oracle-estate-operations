# Fictional Estate Seed Design

This seed dataset is intentionally fictional. It demonstrates the operating model used by the Oracle Estate Operations reference implementation without reproducing employer-specific names, systems, or data.

This document is also the decision record for the V1 fictional estate. The rules below are intentional architecture choices, not incidental properties of the sample data.

## Design principles

The inventory separates business identity, application environment, infrastructure placement, and current operational state rather than trying to encode all of them into one database name.

The hierarchy is:

1. Project/application identifies what the workload is and who owns it.
2. PDB identifies the application environment and is the primary inventory unit.
3. CDB identifies the broad infrastructure class and physical region hosting the PDB.
4. RAC instances and nodes describe supporting infrastructure beneath the CDB.
5. Data Guard role is current operational state and can change without changing database identity.

This supports the Main Inventory goal: answer **What is this? Where is it? Is it healthy? Who owns it? Who should I call?** without requiring an operator to reconstruct those answers from a naming convention alone.

## PDB-first inventory grain

A PDB is the primary unit of the Main Inventory. Each PDB is represented by exactly one Main Inventory row.

CDB, cluster, RAC instance, and node information are supporting infrastructure details. A RAC PDB does not belong to one RAC instance. The CDB contains both its PDBs and its RAC instances; services describe where application workload is expected to run.

Conceptually:

```text
DB_CLUSTER
   |
   +-- CDB
         |
         +-- DB_INSTANCE -> cluster node
         |
         +-- PDB -> environment -> project/application
```

The Main Inventory is intentionally ordered from business context toward infrastructure detail:

```text
Project -> Description -> PDB -> Environment -> CDB -> operational/support detail
```

## CDB naming model

CDB names describe broad infrastructure class and physical location. They do **not** encode the PDB environment or current Data Guard role.

- `N...` = non-production infrastructure
- `P...` = production infrastructure
- trailing `E` = East region
- trailing `W` = West region

Examples:

- `NHR001E` = non-production CDB in the East region
- `PHR001E` = production CDB in the East region
- `PHR001W` = production CDB in the West region

The middle identifier and numeric sequence provide a stable, unique infrastructure identity. They should not be interpreted as the environment of every PDB hosted by the CDB.

### Why Data Guard role is not in the name

A production CDB is not permanently a "primary database" or a "standby database." Either geographically separated peer may become primary after a planned switchover or an unplanned failover.

For example:

```text
Normal state
PHR001E = PRIMARY
PHR001W = STANDBY

After switchover
PHR001E = STANDBY
PHR001W = PRIMARY
```

Neither database is renamed. `database_role` is therefore stored as operational data (`PRIMARY` / `STANDBY`) rather than encoded in the CDB name.

Production Data Guard peers must be geographically separated. A standby in the same region does not satisfy the estate's regional DR intent.

## PDB naming model

The PDB name carries the application environment because the PDB is the application-facing inventory unit.

- `Dnnn` = Development
- `Qnnn` = QA
- `Tnnn` = Test / pre-production validation
- `Annn` = Acceptance / UAT
- `Pnnn` = Production

The numeric portion maps back to the project/application code.

For example, project `001` (HR Reporting) may appear as:

```text
D001  Development
Q001  QA
T001  Test / pre-production
A001  Acceptance / UAT
P001  Production
```

This allows a non-production CDB to host multiple application environments without falsely assigning an environment to the CDB itself.

## Environment and infrastructure isolation

The environment model is deliberately more nuanced than simply "prod" and "nonprod."

### Development and QA

Development and ordinary QA may share general-purpose non-production infrastructure. These environments are expected to experience more frequent change and do not need the same isolation as final production validation tiers.

Example:

```text
NHR001E
├── D001  HR Reporting DEV
├── Q001  HR Reporting QA
├── D002  Order Management DEV
└── Q002  Order Management QA
```

### Test / pre-production

Test is the final production-like test tier and must be isolated from Development/QA. Development activity should not be able to change the infrastructure underneath final pre-production testing.

Test also remains separate from Acceptance/UAT. Sharing the two would reduce the value of independently validating a production-like configuration.

Example:

```text
NHR002E
├── T001  HR Reporting TEST
├── T002  Order Management TEST
└── ...
```

### Acceptance / UAT

Acceptance/UAT is independently isolated and production-like. It is not mixed with Development/QA or Test.

Example:

```text
NHR003E
├── A001  HR Reporting UAT
├── A002  Order Management UAT
└── ...
```

### Production

Production is isolated from all non-production infrastructure.

The production estate uses geographically separated peer CDBs. Matching production PDBs exist on both sides of the Data Guard relationship because the PDBs move with the CDB role rather than being tied to one region as the permanent production site.

```text
East
PHR001E
├── P001  HR Reporting
├── P002  Order Management
└── ...

West
PHR001W
├── P001  HR Reporting
├── P002  Order Management
└── ...
```

The East/West suffix identifies location. The `database_role` column identifies which peer is currently primary.

## Environment vocabulary

The normalized environment values used by the inventory are:

| Code | Meaning |
| --- | --- |
| `DEV` | Development |
| `QA` | Quality Assurance |
| `TEST` | Test / pre-production validation |
| `UAT` | User Acceptance / Acceptance |
| `PERF` | Performance testing |
| `PROD` | Production |
| `DR` | Disaster-recovery business purpose when needed |

Environment and Oracle database role are separate concepts. An environment describes the workload's purpose. `PRIMARY` / `STANDBY` describes the current Oracle role of a CDB.

`PERF` remains a valid environment even though V1 does not require a dedicated performance CDB. Infrastructure should only be created when an operational requirement justifies it.

## V1 topology

| Purpose | CDB | Region | Current role | Isolation intent |
| --- | --- | --- | --- | --- |
| Development / QA | `NHR001E` | East | NONE | General-purpose non-production |
| Test | `NHR002E` | East | NONE | Isolated production-like final test tier |
| Acceptance / UAT | `NHR003E` | East | NONE | Independently isolated production-like acceptance tier |
| Production | `PHR001E` | East | PRIMARY | Production only |
| Production | `PHR001W` | West | STANDBY | Geographically separate production peer |

The current PRIMARY/STANDBY assignment is seed state, not naming semantics.

## Fictional projects

| Project | Application |
| --- | --- |
| `001` | HR Reporting |
| `002` | Order Management |
| `003` | Customer Portal |
| `004` | Finance Analytics |
| `005` | Warehouse Operations |

These project codes provide the numeric portion of the PDB naming convention while the project record holds the human-readable application name and ownership/support metadata.

## Ownership is independent of placement

Application ownership must not be inferred solely from where an object lives.

A PDB has a primary project/application, but accounts and schemas inside that PDB can belong to another project. This is common for integration accounts, database links, shared schemas, and cross-application dependencies.

V1 seed data should intentionally include at least one example where an account resides in one project's PDB but is owned by another project. This demonstrates the rule:

> Where an object lives does not necessarily determine who owns it.

## Services and RAC placement

PDBs are not assigned to individual RAC instances. Services are the mechanism used to express expected workload placement.

The seed estate should therefore model expected and observed service placement independently. V1 intentionally includes at least one service-placement mismatch so `V_SERVICE_COMPLIANCE` demonstrates an operational problem rather than an all-green sample environment.

## Deliberate operational conditions

The fictional estate is not intended to be perfectly healthy. A useful operations dashboard must show what requires attention.

V1 should contain mostly healthy systems plus a small number of intentional conditions:

- one service running on an unexpected RAC instance
- one CDB behind or deferred from its target RU
- one degraded Data Guard transport/apply condition
- one documented and approved standards exception
- one cross-project account ownership example

These are deliberate seed scenarios, not mistakes in the dataset. They should remain small enough that an operator can understand why each dashboard row is abnormal.

## Seed-data philosophy

The seed data should resemble a compact enterprise estate, not a synthetic table-filling exercise. It should be large enough to demonstrate relationships and operational views while remaining understandable during an interview or code review.

The project/application and PDB are the primary business-facing concepts. Infrastructure exists to support those workloads. Seed data should therefore be built in the same order:

```text
Projects / environments
        ↓
Clusters / nodes / CDBs
        ↓
PDBs and project mappings
        ↓
Accounts and ownership
        ↓
Services and RAC expectations
        ↓
Data Guard / patch state / exceptions
```

## Decisions intentionally deferred

The following are not required to prove the V1 model and should not be invented merely to make the estate look larger:

- dedicated performance infrastructure without a stated requirement
- a separate CDB prefix for every PDB environment
- a CDB name that encodes PRIMARY or STANDBY
- a permanent "DR CDB" identity for a database that may become primary
- unnecessary one-to-one mapping between applications and CDBs

Additional infrastructure should be introduced only when it demonstrates an operational requirement that the existing model cannot represent.
