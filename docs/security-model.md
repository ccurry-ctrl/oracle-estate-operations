# Security Model

## Purpose

Define the database security boundary used by `oracle-estate-operations` V1.

The project uses a three-schema pattern so data ownership, application-facing database objects, and runtime access are deliberately separated.

## Schema Roles

### `ESTATE`

`ESTATE` is the DBA-managed data owner.

Expected responsibilities:

- owns base tables;
- owns sequences and other objects that are intrinsic to the stored data model;
- owns data-integrity constraints and indexes;
- grants only the privileges required by the App Objects layer;
- is not used by APEX as its parsing schema;
- is not intended as a routine application login.

### `ESTATE_AO`

`ESTATE_AO` is the **App Objects** owner.

Expected responsibilities:

- owns application-facing views;
- owns materialized views when later justified;
- may own packages or other reusable database logic that belong to the application-facing abstraction rather than the base data model;
- receives explicit object grants from `ESTATE`;
- exposes only the objects required by the runtime layer;
- is not the normal APEX/runtime login.

`AO` means **App Objects**. It is the letter `O`, not the number zero.

### `APPESTATE`

`APPESTATE` is the application/runtime identity and intended APEX parsing schema.

Expected responsibilities:

- receives `CREATE SESSION` and only the object privileges required by the application;
- owns no base estate tables;
- does not receive broad owner-like privileges;
- is used to prove that the application can operate through the intended least-privilege boundary;
- may receive synonyms or narrowly scoped direct grants where they materially improve application usability.

## Access Flow

```text
APEX / runtime
     |
     v
 APPESTATE
     |
 explicit grants
     v
 ESTATE_AO
     |
 explicit grants
     v
   ESTATE
```

Privileges should flow upward only as required for a documented application use case.

The application should not be made functional by granting broad privileges to `APPESTATE` or by changing the APEX parsing schema to an owner account.

## Design Principles

1. **Ownership is deliberate.** Object ownership and runtime identity are different concerns.
2. **Least privilege is testable.** V1 validation should confirm that `APPESTATE` cannot create or alter base owner objects.
3. **Direct grants are explicit.** Avoid blanket role grants that obscure which objects the application requires.
4. **Business logic has a home.** Base data integrity belongs with `ESTATE`; application-facing transformations belong with `ESTATE_AO` unless a concrete design reason says otherwise.
5. **Security failures are design feedback.** If APEX cannot perform an action, first determine the missing privilege and intended ownership boundary rather than bypassing the model.
6. **No production identities.** Schema names, passwords, grants, and examples in this repository are fictional and must not be copied from an employer environment.

## Initial Privilege Intent

The exact DDL is deferred until the logical model is approved, but V1 should begin from this intent:

```text
ESTATE
  owns base objects
  grants SELECT / required DML to ESTATE_AO only where needed

ESTATE_AO
  owns app-facing views and related objects
  grants SELECT / required EXECUTE or DML to APPESTATE only where needed

APPESTATE
  CREATE SESSION
  no CREATE TABLE
  no ALTER ANY ...
  no broad DBA-style roles
```

Where Oracle object semantics require direct access from `APPESTATE` to an `ESTATE` object, that exception should be explicit and documented rather than hidden behind broad privileges.

## Validation Targets

V1 security validation should prove at minimum:

- `ESTATE` owns all base estate tables;
- `ESTATE_AO` owns application-facing views;
- `APPESTATE` can query the objects required by APEX;
- `APPESTATE` cannot create tables;
- `APPESTATE` cannot alter or drop objects owned by `ESTATE` or `ESTATE_AO`;
- APEX runs successfully with `APPESTATE` as its parsing schema;
- no project credentials are committed to Git.

## Future Considerations

Later iterations may add:

- read-only reporting identities;
- ORDS-specific runtime identities or privileges;
- secure application roles;
- database-native auditing of application access;
- enterprise authentication integration;
- credential rotation automation.

Those additions should be driven by a real requirement rather than added only to increase apparent complexity.
