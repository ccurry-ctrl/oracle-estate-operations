-- SQLcl master installation script
-- Run while connected as an administrative account.
-- Example variables are intentionally not stored here.

whenever sqlerror exit sql.sqlcode rollback
set define on
set verify off
set echo on

prompt === Oracle Estate Operations installation ===

accept ESTATE_PASSWORD char prompt 'Password for ESTATE: ' hide
accept ESTATE_AO_PASSWORD char prompt 'Password for ESTATE_AO: ' hide
accept APPESTATE_PASSWORD char prompt 'Password for APPESTATE: ' hide

@@../sql/00-users/create_users.sql

prompt === Creating ESTATE objects ===
alter session set current_schema = ESTATE;
@@../sql/10-estate/tables/core_tables.sql
@@../sql/10-estate/grants/app_object_grants.sql

prompt === Creating ESTATE_AO objects ===
alter session set current_schema = ESTATE_AO;
@@../sql/20-estate_ao/views/operational_views.sql
@@../sql/20-estate_ao/grants/runtime_grants.sql

alter session set current_schema = ADMIN;

prompt === Installation complete. Run validate.sql next. ===
