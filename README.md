# oracle-estate-operations

A small, fictional Oracle estate used to show how I tend to approach database operations: define a supportable standard, make the important state visible, automate the repeatable work, document the exceptions, and leave the result in a condition another DBA can support.

## Why this project exists

Large database estates get hard to operate when every application grows its own naming, deployment, support, and exception patterns. I do not think the answer is to force every workload into the same shape. The useful goal is a clear default, enough structure to make the environment understandable, and an explicit way to handle the places where a workload legitimately differs.

The operating pattern for this project is:

> Define the standard, model the estate, expose useful state, automate repeatable work, document exceptions, and make the result supportable by someone else.

The tools are secondary to that pattern. Oracle, SQLcl, APEX, and scripts are here because they fit the problem being modeled.

## What is implemented

The current V1 foundation includes:

- a normalized Oracle data model for projects, environments, clusters, CDBs, RAC instances, PDBs, services, Data Guard relationships, accounts, patch schedules, and standards exceptions;
- PDB-grain operational inventory with RAC and CDB topology available as supporting detail;
- a three-schema security model separating data ownership, application-facing objects, and runtime access;
- curated operational views for estate status, topology, ownership, service placement, patch readiness, DR status, and active exceptions;
- fictional seed data with a small number of intentional faults and exceptions so validation has something meaningful to report;
- SQLcl installation and validation scripts;
- an Oracle APEX Estate Overview built as a faceted search over `ESTATE_AO.V_ESTATE_STATUS`;
- architecture, standards, security, data-model, seed-design, and operator runbook documentation.

The APEX application is intentionally small. I want the database layer to own the operational rules and APEX to make those rules useful to an operator, not recreate them in page SQL.

## Start here

There are two useful ways into the repository depending on what you are trying to do.

**If you want to understand the design:**

1. [Architecture](docs/architecture.md) — system boundaries and why the pieces are separated.
2. [Estate Standard](docs/estate-standard.md) — the supportable defaults and how exceptions are handled.
3. [Data Model](docs/data-model.md) — how projects, CDBs, PDBs, services, ownership, DR, patching, and exceptions are represented.
4. [Security Model](docs/security-model.md) — schema ownership and the runtime privilege boundary.

**If you want to build the lab:**

1. Start with the [Lab Deployment Runbook](docs/runbooks/lab-deployment.md). It covers the lab prerequisites and gets the Oracle environment ready for this project.
2. Follow the [Database Schema Deployment Runbook](docs/runbooks/deploy-database-schema.md) to install the estate schemas and supporting objects.
3. Run [`deploy/validate.sql`](deploy/validate.sql) and work through the validation results before treating the deployment as complete.
4. The [runbook procedures](docs/runbooks/procedures/) contain the reusable steps used by the higher-level runbooks.

The README is the landing page; the runbooks are the execution path. The design documents explain why the runbooks and database objects are structured the way they are.

## Estate Overview

The Estate Overview presents the fictional estate at PDB grain. It reads directly from `ESTATE_AO.V_ESTATE_STATUS`, so the same database logic can be used by APEX, validation scripts, or another interface without maintaining separate reporting rules.

![Oracle Estate Operations Estate Overview](docs/images/estate-overview.png)

*Estate Overview: PDB-grain inventory with facets for application, environment, database identity, role, ownership, and other support attributes.*

The facets narrow the same inventory to the part of the estate relevant to the question being asked. Filtering to production, for example, makes application ownership and primary/standby placement easy to see without changing the underlying model.

![Oracle Estate Operations production inventory](docs/images/estate-overview-prod.png)

*Production inventory: the same operational view filtered to PROD, showing application ownership and primary/standby placement.*

## Architecture at a glance

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

Oracle is the system of record for the lab. APEX and command-line tooling consume the same operational views instead of rebuilding joins and rules in each interface.

The main inventory is intentionally PDB-grain. A DBA or application owner should be able to start with a PDB and answer the common support questions without first reconstructing the RAC or CDB topology. Infrastructure detail is still available for drill-down and validation, but it does not multiply the primary inventory rows.

See [Architecture](docs/architecture.md) and [Data Model](docs/data-model.md) for the full design.

## Why the schemas are separated

Data ownership, application-facing database objects, and runtime access are different concerns, so V1 keeps them separate:

- `ESTATE` owns the base data model.
- `ESTATE_AO` owns curated application-facing views and related objects.
- `APPESTATE` is the least-privilege runtime identity used by APEX.

`APPESTATE` has no direct access to the `ESTATE` base tables. For read-only interfaces, the project uses Oracle `READ` rather than `SELECT` when locking behavior such as `SELECT ... FOR UPDATE` is not needed.

The extra separation is deliberate because it makes the security boundary visible and testable. If the application cannot do something, I would rather identify the missing privilege or ownership boundary than solve the problem by granting a broad role.

See [Security Model](docs/security-model.md) for the privilege chain and validation targets.

## Standards are defaults, not dogma

The estate standard exists to remove unnecessary variation, not to override a valid application requirement.

A deviation is acceptable when there is a technical or operational reason for it, but the exception should be explicit, owned, reviewable, and visible to the people supporting the system.

The seed data therefore includes a few deliberate conditions:

- an expected-versus-observed RAC service placement mismatch;
- a deferred patch schedule;
- a Data Guard standby with lagging apply;
- an approved naming-standard exception;
- cross-project account ownership.

A completely green demo would be easier to build, but it would say less about operating a real environment.

See [Estate Standard](docs/estate-standard.md) and [Seed Data Design](docs/seed-data-design.md).

## Install and validate

Install the database layer with SQLcl while connected as an administrative account:

```sql
@deploy/install.sql
```

The installer prompts for the three schema passwords rather than storing credentials in the repository. Then run:

```sql
@deploy/validate.sql
```

Validation checks the schema boundary, inventory grain, service placement, patch readiness, Data Guard state, active exceptions, and the intentional seed scenarios.

For lab prerequisites and deployment steps, start with the [Lab Deployment Runbook](docs/runbooks/lab-deployment.md).

## Repository layout

```text
deploy/
  install.sql             master SQLcl installation
  validate.sql            structural and operational validation

docs/
  architecture.md         system boundaries and design
  data-model.md           implemented relationships and inventory grain
  estate-standard.md      default operating standards and exceptions
  security-model.md       schema ownership and privilege model
  seed-data-design.md     fictional topology and test scenarios
  images/                 APEX screenshots used in project documentation
  runbooks/               operator-focused deployment and procedures

sql/
  00-users/               schema creation
  10-estate/              base data model and owner grants
  20-estate_ao/           curated operational views and runtime grants
  30-seed/                fictional estate and operational scenarios
```

## Documentation approach

I treat documentation as part of the operating model, not as the write-up that happens after the engineering is finished.

Top-level runbooks describe the task an operator is trying to complete. Reusable procedures are kept separate so the same steps can be called from more than one runbook without maintaining duplicate instructions. Procedures include prerequisites, actions, validation, stop conditions, failure handling, and a clear definition of completion.

The test is simple: a qualified DBA who did not design the system should be able to understand what it is supposed to do, recognize when it is outside the standard, and know where to look next.

## V1 boundaries

This is not intended to simulate a full enterprise Oracle platform. V1 does not include Terraform provisioning, Ansible configuration management, CI/CD, enterprise SSO, live OEM integration, or production-grade observability.

Those technologies are useful, but they do not belong here just to make the repository look more complicated. I would add them when they solve a concrete operating problem or represent a useful next step in the design.

## Public-safe by design

Everything in this repository is fictional and sanitized. It contains no employer code, credentials, hostnames, application names, proprietary configuration, or copied operating procedures.
