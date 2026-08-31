# oracle-estate-operations

A small, fictional Oracle estate built around a simple operating pattern: define a supportable standard, make the important state visible, automate the repeatable work, document the exceptions, and leave the result in a condition another DBA can support.

## Why this project exists

Large database estates get hard to operate when every application grows its own naming, deployment, support, and exception patterns. The answer is not to force every workload into the same shape. The useful goal is a clear default, enough structure to make the environment understandable, and an explicit way to handle the places where a workload legitimately differs.

The operating pattern for this project is:

> Define the standard, model the estate, expose useful state, automate repeatable work, document exceptions, and make the result supportable by someone else.

The tools are secondary to that pattern. Oracle, SQLcl, APEX, and scripts are here because they fit the problem being modeled.

## What is implemented

V1 includes:

- a normalized Oracle data model for projects, environments, clusters, CDBs, RAC instances, PDBs, services, Data Guard relationships, accounts, patch schedules, and standards exceptions;
- PDB-grain operational inventory with RAC and CDB topology available as supporting detail;
- a three-schema security model separating data ownership, application-facing objects, and runtime access;
- curated operational views for estate status, topology, ownership, service placement, patch readiness, DR status, and active exceptions;
- fictional seed data with a small number of intentional faults and exceptions so validation has something meaningful to report;
- SQLcl install, seed, and validation scripts;
- an Oracle APEX Estate Overview built as a faceted search over `ESTATE_AO.V_ESTATE_STATUS`;
- architecture, standards, security, data-model, and operator runbook documentation.

The APEX application is intentionally small. The database layer owns the operating rules; APEX makes those rules useful to an operator instead of recreating them in page SQL.

The current APEX application is shown here through screenshots. Its export is not part of the V1 repository, so the reproducible path in this repo is the database layer: install, seed, validate.

## Start here

There are two useful ways into the repository.

**If you want to understand the design:**

1. [Architecture](docs/architecture.md) — system boundaries and how the pieces fit together.
2. [Estate Standard](docs/estate-standard.md) — supportable defaults and how exceptions are handled.
3. [Data Model](docs/data-model.md) — projects, CDBs, PDBs, services, ownership, DR, patching, and exceptions.
4. [Security Model](docs/security-model.md) — schema ownership and the runtime privilege boundary.

**If you want to build the lab:**

1. Start with the [Lab Deployment Runbook](docs/runbooks/lab-deployment.md).
2. Use the [Oracle Container Deployment](docs/runbooks/procedures/oracle-container-deploy.md) procedure to build the Ubuntu/Docker runtime.
3. Follow [Deploy Database Schema with SQLcl](docs/runbooks/deploy-database-schema.md).
4. Run the database path in order: `deploy/install.sql`, `deploy/seed.sql`, `deploy/validate.sql`.

The README is the landing page; the runbooks are the execution path. The design documents explain why the database objects and procedures are structured the way they are.

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

## Why the schemas are separated

Data ownership, application-facing database objects, and runtime access are different concerns, so V1 keeps them separate:

- `ESTATE` owns the base data model.
- `ESTATE_AO` owns curated application-facing views.
- `APPESTATE` is the least-privilege runtime identity used by APEX.

`APPESTATE` has no direct access to the `ESTATE` base tables. For read-only interfaces, the project uses Oracle `READ` rather than `SELECT` when locking behavior such as `SELECT ... FOR UPDATE` is not needed.

The separation is deliberate because it makes the security boundary visible and testable. If the application cannot do something, identify the missing privilege or ownership boundary rather than solving the problem with a broad role.

See [Security Model](docs/security-model.md) for the privilege chain and validation targets.

## Standards are defaults, not dogma

The estate standard exists to remove unnecessary variation, not to override a valid application requirement.

A deviation is acceptable when there is a technical or operational reason for it, but the exception should be explicit, owned, reviewable, and visible to the people supporting the system.

The fictional estate therefore includes a few deliberate conditions:

- an expected-versus-observed RAC service placement mismatch;
- a deferred patch schedule;
- a Data Guard standby with lagging apply;
- an approved naming-standard exception;
- cross-project account ownership.

A completely green demo would be easier to build, but it would say less about operating a real environment.

See [Estate Standard](docs/estate-standard.md).

## Install, seed, validate

From SQLcl while connected as an administrative account:

```sql
@deploy/install.sql
@deploy/seed.sql
@deploy/validate.sql
```

The installer prompts for the three schema passwords rather than storing credentials in the repository.

`install.sql` creates the database objects and privilege boundary. `seed.sql` loads the fictional topology and operational scenarios. `validate.sql` checks the structural model, privilege boundary, inventory grain, and the deliberate operating conditions.

For prerequisites and the complete procedure, start with the [Lab Deployment Runbook](docs/runbooks/lab-deployment.md).

## Repository layout

```text
deploy/
  install.sql             database object installation
  seed.sql                fictional topology and operating-state seed
  validate.sql            structural and operational validation

docs/
  architecture.md         system boundaries and design
  data-model.md           implemented relationships and inventory grain
  estate-standard.md      default operating standards and exceptions
  security-model.md       schema ownership and privilege model
  images/                 APEX screenshots
  runbooks/               deployment and reusable operator procedures

sql/
  00-users/               schema creation
  10-estate/              base data model and owner grants
  20-estate_ao/           curated operational views and runtime grants
  30-seed/                fictional topology and operational scenarios
```

## Documentation approach

Documentation is part of the operating model, not the write-up that happens after the engineering is finished.

Top-level runbooks describe the task an operator is trying to complete. Reusable procedures are kept separate when the same steps belong to more than one task. Procedures include prerequisites, actions, validation, stop conditions, failure handling, and a clear definition of completion.

The test is simple: a qualified DBA who did not design the system should be able to understand what it is supposed to do, recognize when it is outside the standard, and know where to look next.

## V1 boundaries

This is not a full enterprise Oracle platform. V1 does not include Terraform provisioning, Ansible configuration management, CI/CD, enterprise SSO, live OEM integration, production-grade observability, or a deployable APEX export.

Those pieces should be added when they solve a concrete operating problem, not simply to make the repository larger.

## Public-safe by design

Everything in this repository is fictional and sanitized. It contains no employer code, credentials, hostnames, application names, proprietary configuration, or copied operating procedures.
