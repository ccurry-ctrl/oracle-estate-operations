# V1 Logical Data Model

## Purpose

Define the initial logical model for the fictional Oracle estate represented by this project.

The model is intentionally centered on **ownership and operational relationships**, not only on database inventory. A database is an important managed asset, but it is not assumed to be the sole source of application identity.

## Core Design Idea

A fictional project/application is represented once, then associated with the databases, schemas/accounts, and other assets that belong to it.

Example:

```text
Project 001: Chris' App

A001   DEV
D001   QA
U001   UAT
P001A  PROD
P001B  PROD
```

Application metadata such as description, owner, SME, manager, and support landing page should be maintained at the project level where possible so it can be changed once and reflected across every related database.

At the same time, assets inside a database may belong to a different project than the database's default application ownership. For example, a database primarily supporting Project 002 may contain an account owned by Project 001 for a database link or integration use case.

The model must therefore preserve the principle:

> Where an object lives does not necessarily determine who owns it.

## Primary Entities

### `PROJECT`

Represents the application/project ownership record.

Initial attributes:

- project identifier;
- application/project name;
- description;
- primary owner;
- SME;
- manager;
- support or application landing page;
- lifecycle/status indicator.

The project identifier is an internal catalog key and should not require parsing database names.

### `ENVIRONMENT`

Defines normalized lifecycle environments independently from naming conventions.

Initial values may include:

- DEV
- QA
- UAT
- PERF
- PROD
- DR
- OTHER

A database name such as `P001A` may communicate useful information to an operator, but application logic should not have to parse the name to determine environment.

### `DATABASE`

Represents a logical Oracle database target in the fictional estate.

Initial attributes:

- database identifier;
- database name;
- environment;
- database type / topology indicator;
- Oracle version;
- operational status;
- Data Guard role where applicable;
- cluster association where applicable;
- description;
- default/primary project relationship;
- patch group;
- lifecycle/status metadata.

A database may support more than one project, so ownership should not be permanently constrained to a single `PROJECT_ID` column if a mapping table provides a cleaner long-term model.

### `DATABASE_PROJECT`

Associates projects with databases.

Initial relationship intent:

- one database may be associated with multiple projects;
- one project may span multiple databases and environments;
- one relationship may be marked as primary/default for display and operational routing.

This avoids duplicating project metadata across each database row.

### `CLUSTER`

Represents a RAC cluster or logical database hosting cluster.

Initial attributes:

- cluster identifier;
- cluster name;
- location/site;
- platform description;
- lifecycle/status metadata.

### `NODE`

Represents a cluster/host node used for service placement and topology display.

Initial attributes:

- node identifier;
- node name;
- cluster identifier;
- operational status.

### `DATABASE_INSTANCE`

Represents the relationship between a logical database and the node/instance on which it runs.

Initial attributes:

- database identifier;
- node identifier;
- instance name;
- instance number where useful;
- observed status.

This supports both single-instance and RAC examples without forcing node columns directly onto the database record.

### `SERVICE`

Represents an Oracle database service.

Initial attributes:

- service identifier;
- database identifier;
- service name;
- purpose/description;
- operational status.

### `SERVICE_PLACEMENT`

Represents expected and observed node placement for a service.

The model should support questions such as:

```text
SERVICE       EXPECTED        OBSERVED        STATUS
sort_app      node1,node2     node1,node2     COMPLIANT
reporting     node3           node2           EXCEPTION
```

Expected state and observed state should remain distinguishable so compliance can be calculated rather than stored as an unexplained flag.

### `DB_ACCOUNT`

Represents an account/schema discovered or cataloged within a database.

Initial attributes:

- account identifier;
- database identifier;
- username/schema name;
- account status;
- last password change date where modeled;
- account type or purpose;
- lifecycle/status metadata.

The account is not assumed to inherit ownership from the database.

### `ACCOUNT_PROJECT`

Associates an account/schema with the project that owns or is responsible for it.

This supports cases such as:

```text
Database P002
  primary project: Project 002

Accounts
  SHAWN_APP       -> Project 002
  APPCHRISAPP     -> Project 001
  MONITOR_USER    -> shared/infrastructure ownership
```

V1 may initially restrict an account to one primary project relationship while preserving a mapping-table design for future flexibility.

### `DR_RELATIONSHIP`

Represents the relationship between primary, standby, or other resiliency targets.

Initial attributes:

- relationship identifier;
- source database;
- target database;
- relationship type;
- expected role;
- observed role/status;
- protection or operational notes.

The model must support justified nonstandard DR patterns as documented exceptions rather than assuming every application uses an identical design.

### `PATCH_GROUP`

Defines a reusable maintenance grouping or patch strategy.

Initial attributes:

- patch group identifier;
- name;
- description;
- cadence or scheduling notes.

### `PATCH_SCHEDULE`

Represents planned and completed maintenance for a database or other managed platform component.

Initial attributes:

- target type;
- target identifier;
- planned date/window;
- patch/RU identifier;
- status;
- completion date;
- notes.

V1 should focus first on database RU scheduling while leaving room for later Grid, DomU, or infrastructure scheduling concepts.

### `STANDARD_EXCEPTION`

Records a deliberate deviation from an estate standard.

Initial attributes:

- exception identifier;
- target type;
- target identifier;
- standard/rule being excepted;
- business or technical reason;
- owner;
- review date;
- status.

An exception is not automatically a failure. A documented, justified, monitored deviation may be compliant with the operating model even though it differs from the default standard.

## Relationship Sketch

```text
PROJECT
  |\
  | \-----------------------+
  |                         |
  v                         v
DATABASE_PROJECT       ACCOUNT_PROJECT
  |                         |
  v                         v
DATABASE -------------- DB_ACCOUNT
  |
  +---- ENVIRONMENT
  |
  +---- CLUSTER ---- NODE
  |          \        /
  |        DATABASE_INSTANCE
  |
  +---- SERVICE ---- SERVICE_PLACEMENT ---- NODE
  |
  +---- DR_RELATIONSHIP ---- DATABASE
  |
  +---- PATCH_GROUP / PATCH_SCHEDULE
  |
  +---- STANDARD_EXCEPTION
```

The exact physical foreign-key implementation may differ slightly once DDL is reviewed. The logical intent is more important than prematurely fixing every join table.

## Ownership as a First-Class Concern

The application should answer four basic questions quickly:

1. **What is this asset?**
2. **Where is it and what role is it performing?**
3. **Is it operating according to the expected standard?**
4. **Who owns it or should be contacted about it?**

Ownership metadata should therefore be reusable across APEX pages and operational views rather than stored as free-text columns repeatedly across unrelated tables.

V1 may begin with owner/SME/manager attributes on `PROJECT` for simplicity. A later normalized `PERSON` / `CONTACT` model should be introduced only if the application develops a real need for shared contact records or multiple responsibility types.

## V1 Operational Views

The physical model should support at least these application-facing views in `ESTATE_AO`:

- `V_ESTATE_STATUS`
- `V_DATABASE_DETAIL`
- `V_SERVICE_COMPLIANCE`
- `V_ACCOUNT_OWNERSHIP`
- `V_PATCH_CALENDAR`
- `V_DR_STATUS`
- `V_STANDARD_EXCEPTIONS`

Naming may be adjusted during DDL review, but the important design rule is that APEX and CLI tooling consume a shared operational abstraction instead of independently reimplementing joins and compliance logic.

## Seed-Data Intent

V1 seed data should contain roughly 20 fictional databases across several fictional applications and environments.

The seed estate should include enough variation to demonstrate real operational questions:

- one RAC application family across DEV/QA/UAT/PROD;
- one single-instance application family;
- several Data Guard relationships;
- one database supporting more than one project;
- at least one account owned by a project different from the database's primary project;
- one service placed on the wrong node;
- one database behind its expected RU;
- one missing or degraded DR condition;
- one documented and justified standards exception that should not be treated as an error.

The goal is not to make the fictional estate artificially unhealthy. It is to provide enough intentional variation that APEX pages and validation tooling demonstrate operational reasoning rather than only displaying inventory.

## Deferred Entities

The following are deliberately deferred until V1 needs them:

- tablespace and datafile history tables;
- detailed capacity trend history;
- OEM target/metric ingestion tables;
- generalized contact/person directory;
- ticket/change-management integration;
- audit-event history;
- cloud tenancy or infrastructure-resource inventory;
- Mongo/document API-specific objects.

These should be added when they support a concrete feature rather than pre-modeled for completeness.

## Review Questions Before DDL

Before generating physical DDL, confirm:

1. Is `PROJECT` the correct reusable application/ownership anchor?
2. Should `DATABASE_PROJECT` allow multiple active project relationships in V1, or should V1 enforce one primary relationship plus optional secondary relationships?
3. Is account/schema ownership correctly independent from database ownership?
4. Is `SERVICE_PLACEMENT` sufficient to model expected versus observed service-node state?
5. Does the initial DR model need anything beyond source, target, type, expected role, observed state, and notes?
6. Are owner, SME, and manager fields sufficient for V1 without introducing a normalized people/contact model?

Once these are agreed, the next change should generate the three schemas, base tables, grants, operational views, validation SQL, and fictional seed data.
