# Architecture

## Purpose

`oracle-estate-operations` is a public-safe reference implementation for operating a fictional enterprise Oracle database estate.

The project is intended to demonstrate an operational engineering pattern:

1. define a supportable standard;
2. collect and normalize operational data;
3. expose useful state and exceptions;
4. automate repetitive validation and maintenance;
5. document the remaining operator actions;
6. preserve justified exceptions instead of forcing uniformity for its own sake.

The repository must remain fictional and sanitized. It must not contain employer code, configuration, hostnames, credentials, application names, or proprietary operating procedures.

## V1 Scope

V1 models approximately 20 fictional Oracle databases supporting several fictional applications.

The estate will include:

- single-instance and RAC databases;
- primary and standby Data Guard roles;
- multiple application owners and support contacts;
- expected database services and node placement;
- patch groups and maintenance schedules;
- database, account/schema, tablespace, and service metadata;
- one documented exception to the normal estate standard.

## Architecture

```text
                  Fictional estate metadata
                           |
                    Oracle Database
                           |
          +----------------+----------------+
          |                                 |
  Operational views                  Compliance views
          |                                 |
          +----------------+----------------+
                           |
                  +--------+--------+
                  |                 |
             Oracle APEX       CLI / scripts
                  |
          Operations portal
```

## Oracle Layer

Oracle is the system of record for the lab.

Initial tables are expected to model:

- database inventory;
- application and ownership metadata;
- clusters and nodes;
- services and expected placement;
- DR configuration and database role;
- account/schema status;
- tablespace and datafile capacity;
- patch groups, schedules, and status;
- documented standard exceptions.

Views will separate stored metadata from operational questions. Initial views should include concepts such as:

- estate status;
- database detail;
- service compliance;
- account health;
- tablespace capacity;
- patch readiness/calendar;
- DR status;
- standards exceptions.

APEX and CLI tooling should consume these views rather than duplicating business rules in multiple interfaces.

## APEX Layer

APEX is the human-facing operations portal, not the source of operational logic.

Initial pages:

1. **Estate Overview** - estate health, database count, roles, clusters, upcoming maintenance, and exceptions.
2. **Database Detail** - role, cluster/node, services, ownership, accounts, storage, DR, and patch information for one database.
3. **Service Compliance** - expected service placement compared with observed placement.
4. **Patch Schedule** - planned RU maintenance by database/application/environment and completion state.

The application should remain intentionally small. The goal is to demonstrate useful operational visibility, not build a complete enterprise monitoring product.

## Automation Layer

V1 will include one command-line validation workflow that reports whether the fictional estate conforms to the same standards represented in Oracle views and APEX.

Automation should be introduced only where it removes repeatable operator work. Procedures should exist before automation when documenting the manual process helps clarify inputs, outputs, guardrails, and failure handling.

## Documentation Model

Top-level runbooks orchestrate a task. Reusable actions live under `docs/runbooks/procedures/`.

A procedure should be independently reusable and should include explicit prerequisites, commands/actions, validation, STOP conditions, failure handling, and completion criteria.

A top-level runbook should link to those procedures rather than duplicate them.

## V1 Non-Goals

The following are intentionally deferred:

- Terraform provisioning;
- Ansible configuration management;
- CI/CD pipelines;
- enterprise authentication or SSO;
- live OEM repository integration;
- production-grade observability;
- simulation of an entire enterprise Oracle estate;
- employer-specific processes or code.

These may be added later when they demonstrate a real engineering progression rather than portfolio decoration.
