# V1 Seed Topology Checkpoint — 2026-08-29

This checkpoint records the state of the Oracle Estate Operations reference implementation after the first populated deployment and validation of the fictional estate topology.

## Completed in this iteration

### Database and security model

The project uses three schemas with intentionally separated responsibilities:

- `ESTATE` — data-owner schema for inventory and operational tables.
- `ESTATE_AO` — App Objects schema for application-facing views and future application objects.
- `APPESTATE` — runtime/APEX-facing schema with minimal privilege.

`APPESTATE` has `CREATE SESSION` and SELECT access to the approved `ESTATE_AO` views. It has no direct grants on `ESTATE` tables.

### Inventory grain

The Main Inventory is PDB-first and business-first. Its grain is one PDB occurrence per `DB_UNIQUE_NAME`.

A mirrored PDB therefore appears once for each Data Guard peer. Example:

```text
Project  Description   PDB   Environment  DB_UNIQUE_NAME  DB_NAME  Role
001      HR Reporting  P001  PROD         PHR001E         PHR001   PRIMARY
001      HR Reporting  P001  PROD         PHR001W         PHR001   STANDBY
```

This is intentional. `DB_NAME` identifies the shared database family while `DB_UNIQUE_NAME` identifies a specific physical Data Guard peer.

### Fictional topology

The populated V1 reference topology contains:

- 5 fictional projects/applications.
- 4 RAC clusters: `NONPROD-EAST`, `NONPROD-WEST`, `PROD-EAST`, `PROD-WEST`.
- 4 nodes per RAC cluster.
- 7 physical CDB/database occurrences.
- 4 RAC instances per physical CDB/database occurrence.
- 40 PDB occurrences.
- 3 Data Guard relationships.

Current database topology:

```text
NONPROD-EAST
├── NHR001 / NHR001E   Development + QA
├── NHR002 / NHR002E   Test PRIMARY
└── NHR003 / NHR003E   UAT PRIMARY

NONPROD-WEST
├── NHR002 / NHR002W   Test STANDBY
└── NHR003 / NHR003W   UAT STANDBY

PROD-EAST
└── PHR001 / PHR001E   Production PRIMARY

PROD-WEST
└── PHR001 / PHR001W   Production STANDBY
```

DEV and QA share the general-purpose non-production CDB. Test and UAT use separate CDB boundaries and mirror production's East/West Data Guard topology. Production remains physically isolated from non-production infrastructure.

### Populated PDB inventory

Each of the five fictional applications has:

- one DEV PDB occurrence
- one QA PDB occurrence
- two TEST PDB occurrences (East/West)
- two UAT PDB occurrences (East/West)
- two PROD PDB occurrences (East/West)

Total: 40 PDB occurrences.

### Data Guard model

Validated relationships:

```text
DB_NAME  PRIMARY_DB_UNIQUE_NAME  STANDBY_DB_UNIQUE_NAME
NHR002   NHR002E                 NHR002W
NHR003   NHR003E                 NHR003W
PHR001   PHR001E                 PHR001W
```

Seed state uses `MAXIMUM PERFORMANCE`, valid transport, and applying standby state. PRIMARY/STANDBY is operational state and is not encoded as permanent identity.

## Validation results

A clean reinstall was performed before the populated seed test. The deployment created:

- 16 `ESTATE` tables
- 8 `ESTATE_AO` views
- no invalid project objects

After `01_reference_topology.sql` was executed, `deploy/validate.sql` completed successfully against populated data.

Validated conditions included:

- exactly one Main Inventory row per `(DB_UNIQUE_NAME, PDB_NAME)` occurrence
- no PDB occurrence with multiple primary project mappings
- 4 RAC instances on 4 distinct nodes for each of the 7 physical CDB/database occurrences
- 40 expected PDB occurrences
- `APPESTATE` retains `CREATE SESSION` only as a system privilege
- no direct `APPESTATE` grants on `ESTATE` tables
- SELECT access to the 8 approved `ESTATE_AO` views

The populated `V_ESTATE_STATUS` and `V_DR_STATUS` views were also manually inspected and matched the intended operating model.

## Operational presentation decisions

The Main Inventory should remain ordered conceptually as:

```text
Project -> Description -> PDB -> Environment -> DB_UNIQUE_NAME -> operational/support detail
```

Environment presentation should use the environment `sort_order` rather than alphabetical environment code. The intended progression is:

```text
DEV -> QA -> TEST -> UAT -> PROD
```

This is a report/APEX presentation concern rather than a reason to impose ordering inside the inventory view.

`DATABASE_ROLE = NONE` for databases outside Data Guard is technically valid but may be presented more cleanly in the eventual APEX UI.

## Deployment lesson captured

`deploy/install.sql` is intentionally a create/install path. Running it against an already-installed lab fails at `CREATE USER`; because SQLcl uses `whenever sqlerror exit`, that failure terminates the SQLcl terminal.

For the validated clean reinstall, the three project schemas were explicitly dropped first and then reinstalled.

Do not make `install.sql` silently destructive. A later improvement should provide an explicit lab reset/reinstall procedure (`deploy/reset.sql` and/or a runbook) so destructive teardown is deliberate and repeatable.

## Current branch state

Work remains on:

```text
feat/seed-estate-data
```

`01_reference_topology.sql` now represents the structural/reference estate and has been executed successfully in the lab.

The next operational seed work should be kept separate rather than expanding the topology seed.

## Next planned implementation

Create:

```text
sql/30-seed/02_operational_state.sql
```

This second seed should populate the operational layers that make the dashboard useful rather than merely descriptive:

1. accounts and ownership, including one intentional cross-project ownership example
2. services and RAC placement expectations
3. one deliberate service-placement mismatch
4. patch groups/schedules, including one behind/deferred CDB
5. one degraded Data Guard transport/apply scenario
6. one documented and approved standards exception

The estate should remain mostly healthy so each abnormal condition is understandable during an interview, demonstration, or code review.

After the operational-state seed is implemented, rerun `deploy/validate.sql` and inspect the corresponding `ESTATE_AO` operational views before beginning the APEX pages.
