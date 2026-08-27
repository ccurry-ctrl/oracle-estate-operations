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

### Naming and Identity

Each database must have:

- a unique database name;
- environment classification such as DEV, QA, UAT, or PROD;
- application name and description;
- primary owner/support contact;
- assigned DBA/support owner;
- deployment type: single instance or RAC.

### High Availability and DR

Production databases must have a documented availability model.

Where Data Guard is used, inventory must identify:

- current database role;
- primary/standby relationship;
- intended protection or availability purpose;
- last known validation state.

A non-standard DR pattern is permitted only as a documented exception.

### Services

Application services must define:

- service name;
- database;
- intended application/purpose;
- expected node placement where applicable;
- observed node placement;
- compliance status derived from expected versus observed state.

### Backup and Recovery

Each database must have:

- an identified backup policy;
- a known last successful backup state;
- recovery expectations appropriate to its environment and criticality;
- documented exceptions when backup or recovery behavior differs from the estate standard.

V1 will model these attributes rather than perform real RMAN backups.

### Monitoring and Ownership

Every database must be represented in the estate inventory with current operational ownership.

The model should make it possible to answer:

- Who owns this application?
- Who supports this database?
- What role is the database currently serving?
- What services should be running?
- Is the database inside its expected operational standard?

### Accounts and Schemas

The operations model will track selected account/schema metadata including:

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

Each database will belong to a patch group or maintenance cohort.

Patch scheduling metadata will include:

- target database;
- environment;
- application owner;
- planned maintenance date;
- patch/RU identifier;
- status;
- exception or deferral reason where applicable.

### Exceptions

Exceptions are first-class operational data, not hidden notes.

Every exception should include:

- affected object or database;
- standard being deviated from;
- business/technical reason;
- owner;
- date recorded;
- review date when appropriate;
- validation or monitoring requirement.

## Initial Fictional Exception

V1 will include one production application with a deliberately non-standard DR arrangement. The purpose is to demonstrate that standardization should improve supportability without overriding a valid application requirement.

The exact fictional implementation will be defined with the seed data so it can be surfaced in both APEX and CLI validation output.
