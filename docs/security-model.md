# Security Model

## Purpose

Define the database security boundary used by `oracle-estate-operations` V1.

The project uses a three-schema pattern so data ownership, application-facing database objects, and runtime access are deliberately separated.

## Schema roles

### `ESTATE`

`ESTATE` is the DBA-managed data owner.

Responsibilities:

- owns the base tables and related data-integrity objects;
- grants only the object access required by the App Objects layer;
- is not used as the APEX parsing schema;
- is not a routine application login.

### `ESTATE_AO`

`ESTATE_AO` is the **App Objects** owner.

Responsibilities:

- owns the curated application-facing views;
- receives explicit object grants from `ESTATE`;
- exposes only the objects required by the runtime layer;
- is not the normal APEX/runtime login.

`AO` means **App Objects**. It is the letter `O`, not the number zero.

### `APPESTATE`

`APPESTATE` is the application/runtime identity and intended APEX parsing schema.

Responsibilities:

- receives `CREATE SESSION` and only the approved object privileges;
- owns no base estate tables;
- has no broad owner-like privileges;
- proves that the application can operate through the intended least-privilege boundary.

## Access flow

```text
APEX / runtime
     |
     v
 APPESTATE
     |
 READ on approved app-facing views
     v
 ESTATE_AO
     |
 READ WITH GRANT OPTION on required base objects
     v
   ESTATE
```

The application should not be made functional by granting broad privileges to `APPESTATE` or by changing the APEX parsing schema to an owner account.

## Design principles

1. **Ownership is deliberate.** Object ownership and runtime identity are different concerns.
2. **Least privilege is testable.** Validation confirms the runtime schema does not have owner-level access.
3. **Direct grants are explicit.** Avoid broad roles that hide which objects the application actually requires.
4. **Business logic has a home.** Base data integrity belongs with `ESTATE`; application-facing transformations belong with `ESTATE_AO` unless there is a concrete reason otherwise.
5. **Security failures are design feedback.** If APEX cannot perform an action, identify the missing privilege and intended ownership boundary before changing the model.
6. **Read-only means read-only.** Prefer Oracle `READ` over `SELECT` for read-only interfaces when `SELECT ... FOR UPDATE` is not required.
7. **No production identities.** Schema names, passwords, grants, and examples in this repository are fictional.

## V1 privilege model

V1 uses this explicit privilege chain:

```text
ESTATE
  owns base objects
  grants READ WITH GRANT OPTION to ESTATE_AO on objects required by app-facing views

ESTATE_AO
  owns app-facing views
  grants READ on approved views to APPESTATE

APPESTATE
  CREATE SESSION
  READ only on approved ESTATE_AO views
  no direct ESTATE table access
  no CREATE TABLE
  no broad DBA-style roles
```

The `WITH GRANT OPTION` on the `ESTATE` to `ESTATE_AO` layer is intentional. `ESTATE_AO` views depend on `ESTATE` base objects and must remain queryable by the downstream runtime schema.

This does **not** grant `APPESTATE` direct access to `ESTATE`. `APPESTATE` remains constrained to the curated `ESTATE_AO` interface.

If a later interface needs write access, the preferred pattern is a controlled PL/SQL API with `EXECUTE` granted to the runtime identity rather than direct `INSERT`, `UPDATE`, or `DELETE` on base tables. V1 does not grant those privileges.

## Validation targets

V1 security validation should prove at minimum:

- `ESTATE` owns all base estate tables;
- `ESTATE_AO` owns the application-facing views;
- required `ESTATE` grants to `ESTATE_AO` are `READ` and grantable;
- `APPESTATE` has `READ` only on the approved `ESTATE_AO` views;
- `APPESTATE` has no direct `ESTATE` table privileges;
- `APPESTATE` cannot create tables;
- APEX can use `APPESTATE` as its parsing schema without expanding that boundary;
- no project credentials are committed to Git.

## V1 boundary

V1 stops at the documented three-schema model. Reporting identities, ORDS-specific identities, secure application roles, database auditing, enterprise authentication, and credential automation should be added only when a concrete requirement calls for them.
