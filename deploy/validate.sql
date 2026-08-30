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

prompt === Service compliance anomalies ===
select db_unique_name,
       pdb_name,
       service_name,
       instance_name,
       expected_flag,
       observed_flag,
       compliance_status
  from ESTATE_AO.v_service_compliance
 where compliance_status = 'MISMATCH'
 order by db_unique_name, pdb_name, service_name, instance_name;

prompt Expected: two rows for HR_REPORTING_TST on NHR002E/T001.

prompt === Deferred patch schedules ===
select db_unique_name,
       patch_group_name,
       target_ru,
       scheduled_date,
       status
  from ESTATE_AO.v_patch_readiness
 where status = 'DEFERRED'
 order by db_unique_name;

prompt Expected: one row for NHR003E in patch group 2026-Q3-RU.

prompt === Data Guard non-healthy state ===
select primary_db_unique_name,
       standby_db_unique_name,
       protection_mode,
       transport_status,
       apply_status
  from ESTATE_AO.v_dr_status
 where transport_status <> 'VALID'
    or apply_status <> 'APPLYING'
 order by primary_db_unique_name;

prompt Expected: one row for NHR003E -> NHR003W with APPLY_STATUS=LAGGING.

prompt === Active standards exceptions ===
select db_unique_name,
       target_name,
       target_type,
       exception_type,
       approved_by,
       review_date
  from ESTATE_AO.v_active_exceptions
 order by db_unique_name, target_name;

prompt Expected: one active NAMING_STANDARD exception for NHR002E/T003.

prompt === Cross-project account ownership ===
select db_unique_name,
       pdb_name,
       account_name,
       account_type,
       project_code,
       application_name,
       primary_flag
  from ESTATE_AO.v_account_ownership
 where account_name = 'FIN_RPT_INTEGRATION';

prompt Expected: NHR002E/T001 owned by project 004 Finance Analytics.

prompt === Validation complete ===
