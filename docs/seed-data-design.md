# Fictional Estate Seed Design

This seed dataset is intentionally fictional. It demonstrates the operating model used by the Oracle Estate Operations reference implementation without reproducing employer-specific names, systems, or data.

## Naming model

CDB names describe broad infrastructure class and location, not application environment or current Data Guard role.

- `N...` = non-production infrastructure
- `P...` = production infrastructure
- trailing `E` = East region
- trailing `W` = West region

A CDB's `database_role` is stored as operational data (`PRIMARY` / `STANDBY`) and is never encoded in its name. This allows a Data Guard switchover without renaming either database.

PDB names carry the application environment:

- `Dnnn` = Development
- `Qnnn` = QA
- `Tnnn` = Test / pre-production validation
- `Annn` = Acceptance / UAT
- `Pnnn` = Production

The numeric portion maps back to the project/application code.

## Environment isolation

Development and QA may share general-purpose non-production infrastructure. Test and Acceptance are isolated from Development/QA and from each other so each can remain stable and production-like for final validation.

Production is isolated from all non-production infrastructure. Production has geographically separate East and West peers; either peer can become primary.

## V1 topology

| Purpose | CDB | Region | Current role | Notes |
| --- | --- | --- | --- | --- |
| Development / QA | `NHR001E` | East | NONE | General non-production workload |
| Test | `NHR002E` | East | NONE | Isolated production-like test tier |
| Acceptance / UAT | `NHR003E` | East | NONE | Isolated production-like acceptance tier |
| Production | `PHR001E` | East | PRIMARY | Current production primary |
| Production | `PHR001W` | West | STANDBY | Geographically separate production peer |

Production peers contain matching production PDBs. Their names remain stable when Data Guard roles change.

## Fictional projects

| Project | Application |
| --- | --- |
| `001` | HR Reporting |
| `002` | Order Management |
| `003` | Customer Portal |
| `004` | Finance Analytics |
| `005` | Warehouse Operations |

The Main Inventory remains PDB-first: project/application context appears first, followed by PDB, environment, CDB, role, and supporting infrastructure details.
