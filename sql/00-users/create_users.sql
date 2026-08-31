-- Run as an administrative account.
-- Passwords are supplied as SQLcl substitution variables and must not be committed.

whenever sqlerror exit sql.sqlcode rollback
set verify off

prompt Creating ESTATE data-owner schema
create user ESTATE identified by "&&ESTATE_PASSWORD";
grant create session, create table, create sequence to ESTATE;
alter user ESTATE quota unlimited on DATA;

prompt Creating ESTATE_AO App Objects schema
create user ESTATE_AO identified by "&&ESTATE_AO_PASSWORD";
grant create session, create view to ESTATE_AO;
alter user ESTATE_AO quota unlimited on DATA;

prompt Creating APPESTATE runtime schema
create user APPESTATE identified by "&&APPESTATE_PASSWORD";
grant create session to APPESTATE;

prompt Schema bootstrap complete
