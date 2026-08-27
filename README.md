# oracle-estate-operations

Reference implementation for standardizing, automating, and operating a fictional enterprise Oracle database estate.

## What this project demonstrates

The project models a small Oracle estate and the operating practices around it. The goal is not to reproduce a production environment. It is to show how a database estate can be made easier to understand, safer to operate, and easier to hand off through:

- clear operational standards;
- reusable database metadata and compliance views;
- automation of repetitive validation and maintenance;
- an Oracle APEX operations portal;
- documented exceptions where application requirements justify them;
- runbooks that separate orchestration from reusable procedures.

The repository is intentionally fictional and sanitized. It contains no employer code, configuration, credentials, hostnames, or proprietary application data.

## V1

V1 will model approximately 20 fictional Oracle databases with a mix of:

- single-instance and RAC deployments;
- Data Guard primary/standby roles;
- application ownership and support metadata;
- database services and expected node placement;
- patch groups and maintenance schedules;
- account/schema and storage information;
- one documented exception to the normal estate standard.

The first APEX application will provide:

1. Estate Overview
2. Database Detail
3. Service Compliance
4. Patch Schedule

A command-line validation workflow will consume the same underlying Oracle views used by APEX.

## Repository layout

```text
docs/
  architecture.md
  estate-standard.md
  runbooks/
    lab-deployment.md
    procedures/
sql/
  schema/
  seed/
  views/
  validation/
apex/
  export/
scripts/
compose/
```

Directories will be added as implementation begins.

## Documentation

- [Architecture](docs/architecture.md)
- [Estate Standard](docs/estate-standard.md)
- [Lab Deployment Runbook](docs/runbooks/lab-deployment.md)

## Design principle

The project follows a simple progression:

> Understand the problem, define the standard, automate the repeatable work, expose useful state, document the remainder, and make the result supportable by someone else.
