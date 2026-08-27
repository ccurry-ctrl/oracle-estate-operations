whenever sqlerror exit sql.sqlcode rollback
set pagesize 100
set linesize 180

prompt === Schema status ===
select username, account_status
  from dba_users
 where username in ('ESTATE','ESTATE_AO','APPESTATE')
 order by username;

prompt === ESTATE object counts ===
select object_type, count(*) object_count
  from dba_objects
 where owner = 'ESTATE'
 group by object_type
 order by object_type;

prompt === ESTATE_AO object counts ===
select object_type, count(*) object_count
  from dba_objects
 where owner = 'ESTATE_AO'
 group by object_type
 order by object_type;

prompt === Invalid objects ===
select owner, object_name, object_type, status
  from dba_objects
 where owner in ('ESTATE','ESTATE_AO','APPESTATE')
   and status <> 'VALID';

prompt === APPESTATE system privileges ===
select privilege
  from dba_sys_privs
 where grantee = 'APPESTATE'
 order by privilege;

prompt Expected: CREATE SESSION only.

prompt === APPESTATE direct ESTATE table grants ===
select owner, table_name, privilege
  from dba_tab_privs
 where grantee = 'APPESTATE'
   and owner = 'ESTATE';

prompt Expected: no rows.

prompt === APPESTATE ESTATE_AO grants ===
select owner, table_name, privilege
  from dba_tab_privs
 where grantee = 'APPESTATE'
   and owner = 'ESTATE_AO'
 order by table_name, privilege;

prompt === Validation complete ===
