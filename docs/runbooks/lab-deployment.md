# Lab Deployment Runbook

## Purpose

Build a disposable Oracle Estate Operations lab from a clean Linux host, deploy the fictional estate, and verify that the database layer is working as documented.

The lab does not depend on my workstation or home-server layout. Windows, macOS, or Linux is fine for the operator workstation. The lab host just needs to meet the requirements below.

## What this runbook assumes

This is written for a DBA or infrastructure engineer who is comfortable following a technical runbook and using a command line, but may not spend much time building Linux or container infrastructure.

I am not going to reproduce general Linux, Git, Docker, or virtualization documentation here. Use the current documentation for those tools when you need it. Once the host meets the prerequisites, this runbook takes over.

## Recommended lab layout

Ubuntu Server LTS is the recommended lab host because it is common, well documented, and easy to reproduce. A VM is sufficient. The VM can run on VirtualBox, VMware, Hyper-V, or another hypervisor that works for your workstation.

A physical Linux host is also fine. Nothing in the project requires a particular hypervisor or a particular operator OS.

```text
Operator workstation
Windows / macOS / Linux
        |
        | Git / SSH / SQLcl / Browser
        v
Ubuntu Server LTS
        |
        +-- Docker
        |
        +-- Oracle Free container
              +-- Oracle Database
              +-- ORDS / APEX
                    |
                    v
          Oracle Estate Operations
```

Treat the lab host as disposable. The repository and documented procedure are the authoritative parts. If the VM becomes a collection of undocumented fixes, rebuilding it is usually the better answer.

## Prerequisites

### Operator workstation

You need:

- Git;
- an SSH client;
- SQLcl or another Oracle command-line client capable of running the supplied SQL scripts;
- a web browser for APEX;
- an editor or IDE of your choice.

VS Code works well, but it is not required.

### Lab host

You need:

- a supported Linux host, with Ubuntu Server LTS recommended;
- Docker Engine installed and working;
- enough CPU, memory, and storage for the Oracle Free container;
- network connectivity from the operator workstation to the database and APEX/ORDS endpoints;
- a dedicated writable directory for the lab.

Use the current Docker and Oracle container documentation when sizing a new VM. Give Oracle enough room to run normally rather than tuning a first deployment to the smallest possible footprint.

Before continuing, verify Docker independently. A broken Docker installation is a host problem, not an Oracle Estate Operations problem.

**PASS:** You can connect to the lab host, Docker runs successfully, and the operator workstation can reach the host.

**STOP:** Fix the host, Docker, or network path before continuing.

## Scope

This runbook covers:

- deploying the Oracle Free container used by the lab;
- deploying the three estate schemas;
- loading the fictional reference topology and operational scenarios;
- creating the operational views used by validation and APEX;
- validating the database layer;
- confirming the APEX/ORDS endpoint used by the lab.

V1 includes an APEX Estate Overview built over `ESTATE_AO.V_ESTATE_STATUS`. The database objects and SQL validation are reproducible from this repository. The APEX application itself is currently a small UI layer and is not treated as the source of operational logic.

This runbook does not cover production hardening, enterprise authentication, CI/CD, Terraform, Ansible, live OEM integration, or general virtualization administration.

## Operator guardrails

- Treat the lab as disposable.
- Do not use employer data, code, hostnames, credentials, or application names.
- Do not place secrets in Git.
- Read a command before running it.
- Stop when a validation gate fails. Do not continue hoping a later step repairs an earlier problem.
- Prefer the documented procedure over an ad hoc fix. If the procedure is wrong, fix the procedure.

## 1. Choose the lab location

Choose a dedicated writable directory on the Linux host. An ordinary Linux filesystem is fine. The project does not require ZFS or any other specific storage layout.

Keep the lab separate from directories used by existing applications or production-like services.

**PASS:** The lab has its own writable location with sufficient free space and no dependency on an unrelated application.

**STOP:** Choose another location if the proposed path would mix the lab with existing service configuration or data.

## 2. Deploy Oracle Free

Follow [Oracle Container Deployment](procedures/oracle-container-deploy.md).

That procedure covers the container deployment, persistent lab storage, required ports, and the checks used to determine whether the database and ORDS/APEX endpoint are healthy.

Do not continue merely because the container exists. Complete the validation in the procedure first.

**PASS:** Oracle is open and accepting connections, the expected listener is available, and the ORDS/APEX endpoint responds.

**STOP:** Resolve the container, database, listener, or endpoint failure before deploying the estate schemas.

## 3. Deploy Oracle Estate Operations

From the cloned repository, connect with SQLcl as an administrative database account and run:

```sql
@deploy/install.sql
```

The installer prompts for the `ESTATE`, `ESTATE_AO`, and `APPESTATE` passwords. Passwords are not stored in the repository.

The install creates the schema boundary, base model, application-facing views, grants, fictional topology, and operational scenarios.

For the schema-specific procedure and expected deployment behavior, see [Database Schema Deployment](../deploy-database-schema.md).

**PASS:** The install completes without unexplained SQL errors.

**STOP:** Do not manually create missing objects to get past a failed install. Identify the failed deployment step, correct the script or prerequisite responsible, and run the documented deployment again.

## 4. Validate the database layer

Run:

```sql
@deploy/validate.sql
```

Validation checks the implemented model rather than simply checking that tables exist. It covers the schema boundary, inventory grain, service placement, patch readiness, Data Guard state, active exceptions, and the intentional seed scenarios.

The fictional estate contains 40 PDB occurrences across seven physical CDB occurrences, four RAC clusters, five projects, and three Data Guard relationships. It also contains a small number of deliberately unhealthy or non-standard conditions so the operational views have something useful to report.

See [Seed Data Design](../seed-data-design.md) for the topology and the reason each intentional condition exists.

**PASS:** Structural checks succeed and the documented operational exceptions appear where expected.

**STOP:** An unexplained invalid object, missing relationship, privilege failure, or unexpected operational result is a deployment failure. Resolve it before treating the lab as complete.

## 5. Confirm the APEX layer

Confirm that the ORDS/APEX endpoint is reachable from the operator workstation.

The current V1 UI is the **Estate Overview**, a faceted search over `ESTATE_AO.V_ESTATE_STATUS`. It presents the same PDB-grain inventory used by the database layer rather than maintaining a second set of joins and operating rules inside APEX.

The screenshots in the [README](../../README.md#estate-overview) show the expected V1 interface.

**PASS:** The endpoint is reachable and the Estate Overview displays the fictional estate from the shared operational view.

**STOP:** Do not solve an APEX access problem by granting broad access to the `ESTATE` base tables. Use the documented [Security Model](../security-model.md) to identify the missing runtime privilege or ownership boundary.

## Failure handling

When a step fails:

1. stop at the failed gate;
2. capture the command output or UI condition;
3. decide whether the problem belongs to the host, a prerequisite, or this repository;
4. correct the responsible procedure or implementation artifact when the problem is ours;
5. repeat the failed step;
6. continue only after its PASS condition is met.

Do not turn a successful one-off recovery command into undocumented required knowledge. If another operator would need it, it belongs in the procedure.

## Completion criteria

The lab is ready when:

- Oracle is healthy and accepting connections;
- ORDS/APEX is reachable;
- the three-schema security boundary is deployed;
- the fictional estate and operational scenarios are loaded;
- `deploy/validate.sql` completes with the expected results;
- the documented intentional exceptions are visible rather than silently ignored;
- the Estate Overview can read the shared operational view through the documented runtime boundary;
- another qualified operator could rebuild the lab without knowing how the original host was configured.

At that point, the VM or host is replaceable. That is intentional.
