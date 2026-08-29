# Estate Standard

## Purpose

Define the default operating standard for the fictional Oracle estate used by this project.

The standard exists to reduce unnecessary variation and make databases easier for any qualified DBA to support. It is a default, not an absolute rule. Deviations are allowed when an application or operational requirement justifies them, but exceptions must be explicit and documented.

## Standardization Principles

1. Prefer repeatable configuration over database-specific conventions.
2. Keep operational metadata visible and current.
3. Automate controls that are deterministic and frequently repeated.
4. Keep support procedures independent of individual operator knowledge.
5. Document exceptions with an owner, reason, and validation method.
6. Do not force a workload into the standard when doing so reduces reliability or supportability.

## V1 Standards

### Inventory Grain

The main inventory is one row per PDB.

Each PDB must identify:

- its PDB name;
- parent CDB;
- environment classification such as DEV, QA, UAT, PERF, or PROD;
- application/project relationship;
- primary owner/support contacts;
- current operational state.

CDB, RAC instance, cluster, and node data are supporting infrastructure context. They must be available for drill-down and reporting without changing the one-row-per-PDB grain of the main inventory.

### CDB and RAC Topology

Each CDB must identify:

- CDB name and DB unique name;
- deployment type: single instance or RAC;
- current database role;
- Oracle version;
- cluster where applicable.

For RAC CDBs, inventory must identify each database instance and the cluster node on which it runs. For example, CDB `ABC` may have instances `ABC1`, `ABC2`, `ABC3`, and `ABC4` across four nodes.

PDBs belong to the CDB, not to individual RAC instances.

### Naming and Identity

Surrogate relational keys should use Oracle identity columns where the value has no operational meaning.

Human-entered identifiers that carry operational meaning should remain explicit attributes and use uniqueness constraints where appropriate.

### High Availability and DR

Production CDBs must have a documented availability model.

Where Data Guard is used, inventory must identify:

- current database role;
- primary/standby CDB relationship;
- intended protection or availability purpose;
- last known validation state.

A non-standard DR pattern is permitted only as a documented exception.

### Services

Application services must define:

- service name;
- PDB served;
- intended application/purpose;
- expected RAC instance placement where applicable;
- observed instance placement;
- compliance status derived from expected versus observed state.

### Backup and Recovery

Each database must have:

- an identified backup policy;
- a known last successful backup state;
- recovery expectations appropriate to its environment and criticality;
- documented exceptions when backup or recovery behavior differs from the estate standard.

V1 will model these attributes rather than perform real RMAN backups.

### Monitoring and Ownership

Every PDB must be represented in the estate inventory with current operational ownership.

The model should make it possible to answer:

- What PDB is this application using?
- Who owns this application?
- Who supports this database?
- Which CDB hosts the PDB?
- Which RAC instances and nodes support that CDB?
- What services should be running and where?
- Is the database inside its expected operational standard?

### Accounts and Schemas

The operations model will track selected account/schema metadata at the PDB level including:

- account status;
- last password change or equivalent age indicator;
- schema/application ownership;
- exceptions requiring attention.

No real credentials or password hashes will be stored.

### Storage

The model will expose tablespace and datafile capacity sufficient to identify:

- current allocation;
- utilization;
- threshold exceptions;
- abnormal growth conditions in later versions.

### Patching

CDBs will belong to patch groups or maintenance cohorts because RU lifecycle state is infrastructure-level data.

Patch scheduling metadata will include:

- target CDB;
- affected PDB/application context through inventory relationships;
- planned maintenance date;
- patch/RU identifier;
- status;
- exception or deferral reason where applicable.

### Exceptions

Exceptions are first-class operational data, not hidden notes.

Every exception should include:

- affected PDB, CDB, or estate scope;
- standard being deviated from;
- business/technical reason;
- owner;
- date recorded;
- review date when appropriate;
- validation or monitoring requirement.

## Initial Fictional Exception

V1 will include one production application with a deliberately non-standard DR arrangement. The purpose is to demonstrate that standardization should improve supportability without overriding a valid application requirement.

The exact fictional implementation will be defined with the seed data so it can be surfaced in both APEX and CLI validation output.
