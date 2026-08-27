# Lab Deployment Runbook

## Purpose

Deploy the V1 Oracle Estate Operations lab from a clean host state to a validated Oracle database, APEX/ORDS endpoint, fictional estate schema, and initial operations portal.

This runbook orchestrates the deployment. Reusable actions belong in `docs/runbooks/procedures/` and should be followed from there rather than duplicated here.

## Scope

This runbook covers:

- Oracle lab deployment;
- schema deployment;
- fictional seed data;
- operational/compliance views;
- APEX workspace/application setup;
- initial validation.

It does not cover production hardening, enterprise authentication, CI/CD, Terraform, Ansible, or live OEM integration.

## Operator Guardrails

- Treat the lab as disposable.
- Do not use employer data, code, hostnames, credentials, or application names.
- Do not place secrets in Git.
- Stop when a validation gate fails. Do not continue hoping a later step repairs an earlier problem.
- Prefer the documented procedure over ad hoc corrective steps. If the procedure is wrong, fix the procedure.

## Related Procedures

Procedures will be added as implementation begins:

- Oracle container deployment
- schema deployment
- sample data load
- APEX workspace setup
- APEX application import/build
- lab validation

## 1. Prepare Lab Location

Confirm the target host and storage location are appropriate for disposable lab workloads.

**PASS:** A dedicated writable lab path is available with sufficient storage and no dependency on production services.

**STOP:** The proposed path contains production/service configuration or would create a dependency on an existing application.

## 2. Deploy Oracle Database and ORDS/APEX

Follow the Oracle deployment procedure once created.

**PASS:** Database is open and accepting connections; ORDS/APEX endpoint responds successfully.

**STOP:** Database is not healthy, required ports are unavailable, or the APEX/ORDS endpoint cannot be reached.

## 3. Deploy Estate Schema

Follow the schema deployment procedure.

The deployment must create the V1 metadata model without employer-specific objects or naming.

**PASS:** Required schema objects compile successfully and validation reports no invalid required objects.

**STOP:** DDL fails, required objects are invalid, or deployment requires undocumented manual changes.

## 4. Load Fictional Estate Data

Follow the sample-data procedure.

Seed data should represent approximately 20 fictional databases and include the documented standards exception.

**PASS:** Expected row counts are present and referential-integrity checks pass.

**STOP:** Seed data contains real environment information, unresolved constraint failures, or inconsistent relationships.

## 5. Deploy Operational and Compliance Views

Deploy the V1 views used by both APEX and CLI validation.

**PASS:** Views compile and return expected fictional estate state, including at least one compliant result and one intentional exception.

**STOP:** APEX-specific logic must be duplicated to make the views useful, or core compliance logic exists only in presentation code.

## 6. Configure APEX Workspace

Follow the APEX workspace setup procedure.

**PASS:** Workspace authentication succeeds and the estate schema is assigned to the workspace.

**STOP:** Workspace cannot authenticate or the application schema is unavailable.

## 7. Build or Import V1 APEX Application

Create/import the initial pages:

1. Estate Overview
2. Database Detail
3. Service Compliance
4. Patch Schedule

**PASS:** Each page loads and displays data from the shared Oracle views.

**STOP:** Pages require hard-coded production-like values, expose credentials, or duplicate core estate rules in page logic.

## 8. Run Lab Validation

Follow the lab validation procedure.

Validation should confirm at minimum:

- expected schema objects exist;
- required views are valid;
- fictional estate row counts are plausible;
- service compliance identifies expected state and intentional exceptions;
- APEX endpoint is reachable;
- no obvious secret or employer-specific strings are present in tracked project files.

**PASS:** All required checks pass or only documented intentional exceptions remain.

**STOP:** Any unexplained validation failure remains.

## Failure Handling

If a step fails:

1. stop at the failed gate;
2. capture the command/output or UI condition;
3. correct the reusable procedure or implementation artifact responsible for the failure;
4. repeat the failed procedure;
5. resume this runbook only after the PASS condition is met.

Do not add one-off recovery commands to this orchestration runbook when they belong in a reusable procedure.

## Completion Criteria

The V1 deployment is complete when:

- Oracle database is healthy;
- ORDS/APEX is reachable;
- fictional estate schema and seed data are deployed;
- operational/compliance views are valid;
- the four initial APEX pages are functional;
- CLI validation produces understandable output;
- the documented standards exception is visible rather than silently ignored;
- a second operator could reproduce the deployment using repository documentation without relying on undocumented knowledge.
