# Estate Standard

## Purpose

This document defines the default operating standard for the fictional Oracle estate.

The standard exists to reduce unnecessary variation and make the environment easier for any qualified DBA to support. It is a default, not an absolute rule. A workload can differ when there is a valid technical or operational reason, but the exception should be explicit, owned, reviewable, and visible.

## Standardization principles

1. Prefer repeatable configuration over database-specific conventions.
2. Keep operational metadata visible and current.
3. Automate checks that are deterministic and repeatedly performed.
4. Keep support procedures independent of one person's memory.
5. Record exceptions with an owner, reason, and review point.
6. Do not force a workload into the standard when doing so makes it less reliable or harder to support.

## Inventory grain

The main inventory is one PDB occurrence per `DB_UNIQUE_NAME`.

Each inventory row identifies:

- PDB name;
- parent CDB / `DB_UNIQUE_NAME`;
- environment;
- application/project relationship;
- database role and open mode;
- owner, SME, and manager;
- Oracle version, architecture type, and cluster where applicable.

CDB, RAC instance, cluster, and node data are supporting infrastructure context. They remain available without multiplying the main PDB inventory rows.

## CDB and RAC topology

Each CDB records:

- `DB_NAME` / CDB name;
- `DB_UNIQUE_NAME`;
- single-instance or RAC architecture;
- current database role;
- Oracle version;
- cluster association where applicable.

RAC instances are modeled separately and tied to cluster nodes.

PDBs belong to the CDB, not to an individual RAC instance. Services express expected workload placement.

## Naming and identity

Surrogate relational keys use Oracle identity columns where the value has no operational meaning.

Human-facing identifiers that do carry operational meaning remain explicit attributes with uniqueness constraints where appropriate.

Environment and Data Guard role are stored as data instead of being inferred from a database name. Names may help an operator, but application logic should not depend on parsing them for state that can change.

## Application access and privileges

Runtime schemas receive only the privileges required by the application interface.

For read-only application-facing views, use Oracle `READ` rather than `SELECT` when `SELECT ... FOR UPDATE` is not required.

The privilege chain is:

```text
ESTATE
  owns base objects
  grants READ WITH GRANT OPTION to ESTATE_AO

ESTATE_AO
  owns curated application-facing views
  grants READ on approved views to APPESTATE

APPESTATE
  CREATE SESSION
  READ on approved ESTATE_AO views
  no direct ESTATE table access
```

If write operations are introduced later, prefer controlled PL/SQL package interfaces with `EXECUTE` grants over direct DML on base tables.

## High availability and Data Guard

Production-like CDBs have an explicit availability model.

Where Data Guard is used, inventory records:

- primary and standby peers;
- current database role;
- protection mode;
- transport status;
- apply status.

Role is operating state, not identity. A switchover should not require renaming either peer.

A non-standard DR arrangement is acceptable only when it is documented as an exception.

## Services

Application services record:

- service name;
- PDB served;
- expected RAC instance placement;
- observed instance placement.

Compliance is derived from expected versus observed state rather than maintained as an unexplained manual flag.

## Ownership

Every PDB has an application/project relationship and operational contacts.

Accounts have their own project relationships because account ownership does not always match the PDB's primary application. Cross-project integration accounts are represented directly instead of being treated as bad data.

The model should make these questions easy to answer:

- What is this PDB for?
- Which environment is it?
- Which physical database is hosting it?
- What role is that database performing?
- Who owns and supports the application?
- What services should be running and where?
- Is there a known exception I need to understand before changing anything?

## Patching

RU scheduling is modeled at CDB level.

Each scheduled CDB records:

- patch group;
- target RU;
- scheduled date;
- completion date;
- status such as PLANNED, READY, COMPLETE, DEFERRED, or FAILED.

Application context is reached through the CDB-to-PDB relationships rather than duplicated into the patch record.

## Exceptions

Exceptions are first-class operational data, not hidden notes.

An exception targets either a PDB or a CDB and records:

- exception type;
- description;
- technical or business justification;
- approver;
- review date;
- active state.

A documented exception is not automatically a failure. The point is to make the deviation visible enough that the next operator understands why it exists and what must still be validated.

## V1 validation conditions

The fictional estate deliberately includes a small number of non-green conditions:

- a RAC service placement mismatch;
- a deferred patch schedule;
- a Data Guard standby with lagging apply;
- an approved naming-standard exception;
- a cross-project account ownership case.

These are not mistakes in the seed data. They exist so the validation and reporting layers prove they can surface real operating questions instead of only displaying a perfect environment.

## Not modeled in V1

V1 does not model RMAN backup execution, capacity history, OEM ingestion, change-management integration, or production observability.

Those controls belong here when the project has enough underlying data or automation to make them testable. Writing requirements that the implementation cannot prove would add documentation without adding control.
