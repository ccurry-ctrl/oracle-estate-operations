-- SQLcl seed orchestration for the fictional Oracle estate.
-- Run after deploy/install.sql and before deploy/validate.sql.

whenever sqlerror exit sql.sqlcode rollback
set echo on

prompt === Oracle Estate Operations seed ===

@@../sql/30-seed/01_reference_topology.sql
@@../sql/30-seed/02_operational_state.sql

prompt === Seed complete. Run validate.sql next. ===
