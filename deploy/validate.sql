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

prompt === Main inventory grain check ===
select db_unique_name, pdb_name, count(*) row_count
  from ESTATE_AO.v_estate_status
 group by db_unique_name, pdb_name
having count(*) <> 1;

prompt Expected: no rows. V_ESTATE_STATUS must return one row per PDB occurrence on each DB_UNIQUE_NAME.

prompt === Multiple primary projects per PDB occurrence ===
select pdb_id, count(*) primary_project_count
  from ESTATE.pdb_project
 where primary_flag = 'Y'
 group by pdb_id
having count(*) > 1;

prompt Expected: no rows.

prompt === RAC instance topology ===
select c.db_unique_name,
       c.cdb_name,
       count(i.instance_id) instance_count,
       count(distinct i.node_id) node_count
  from ESTATE.cdb c
  left join ESTATE.db_instance i on i.cdb_id = c.cdb_id
 group by c.db_unique_name, c.cdb_name
 order by c.db_unique_name;

prompt === PDB to CDB inventory ===
select p.pdb_name,
       c.db_unique_name,
       c.cdb_name,
       e.environment_code
  from ESTATE.pdb p
  join ESTATE.cdb c on c.cdb_id = p.cdb_id
  join ESTATE.environment e on e.environment_id = p.environment_id
 order by c.db_unique_name, p.pdb_name;

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
