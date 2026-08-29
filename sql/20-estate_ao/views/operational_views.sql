whenever sqlerror exit sql.sqlcode rollback

-- Main inventory: exactly one row per PDB.
-- Present the business/application identity first, then the Oracle hosting detail.
create or replace view v_estate_status as
select pr.project_code,
       pr.application_name as description,
       p.pdb_name,
       e.environment_code,
       c.cdb_name,
       c.database_role,
       p.open_mode,
       pr.owner_name,
       pr.sme_name,
       pr.manager_name,
       c.oracle_version,
       c.architecture_type,
       cl.cluster_name,
       p.active_flag,
       p.pdb_id,
       c.db_unique_name
  from ESTATE.pdb p
  join ESTATE.cdb c on c.cdb_id = p.cdb_id
  join ESTATE.environment e on e.environment_id = p.environment_id
  left join ESTATE.db_cluster cl on cl.cluster_id = c.cluster_id
  left join ESTATE.pdb_project pp
    on pp.pdb_id = p.pdb_id
   and pp.primary_flag = 'Y'
  left join ESTATE.project pr on pr.project_id = pp.project_id;

-- Supporting infrastructure view: CDB and RAC instance/node topology.
create or replace view v_cdb_instance_status as
select c.cdb_id,
       c.cdb_name,
       c.db_unique_name,
       c.architecture_type,
       c.database_role,
       cl.cluster_name,
       i.instance_id,
       i.instance_name,
       i.instance_number,
       n.node_name,
       i.status instance_status,
       i.active_flag
  from ESTATE.cdb c
  left join ESTATE.db_cluster cl on cl.cluster_id = c.cluster_id
  left join ESTATE.db_instance i on i.cdb_id = c.cdb_id
  left join ESTATE.cluster_node n on n.node_id = i.node_id;

create or replace view v_pdb_ownership as
select p.pdb_name,
       c.cdb_name,
       e.environment_code,
       pr.project_code,
       pr.application_name,
       pr.owner_name,
       pr.sme_name,
       pr.manager_name,
       pp.primary_flag
  from ESTATE.pdb p
  join ESTATE.cdb c on c.cdb_id = p.cdb_id
  join ESTATE.environment e on e.environment_id = p.environment_id
  join ESTATE.pdb_project pp on pp.pdb_id = p.pdb_id
  join ESTATE.project pr on pr.project_id = pp.project_id;

create or replace view v_account_ownership as
select p.pdb_name,
       c.cdb_name,
       a.account_name,
       a.account_type,
       a.account_status,
       a.last_password_change,
       pr.project_code,
       pr.application_name,
       pr.owner_name,
       ap.primary_flag
  from ESTATE.db_account a
  join ESTATE.pdb p on p.pdb_id = a.pdb_id
  join ESTATE.cdb c on c.cdb_id = p.cdb_id
  left join ESTATE.account_project ap on ap.account_id = a.account_id
  left join ESTATE.project pr on pr.project_id = ap.project_id;

create or replace view v_service_compliance as
select p.pdb_name,
       c.cdb_name,
       s.service_name,
       i.instance_name,
       n.node_name,
       sie.expected_flag,
       sie.observed_flag,
       case when sie.expected_flag = sie.observed_flag then 'COMPLIANT' else 'MISMATCH' end compliance_status
  from ESTATE.db_service s
  join ESTATE.pdb p on p.pdb_id = s.pdb_id
  join ESTATE.cdb c on c.cdb_id = p.cdb_id
  join ESTATE.service_instance_expectation sie on sie.service_id = s.service_id
  join ESTATE.db_instance i on i.instance_id = sie.instance_id
  join ESTATE.cluster_node n on n.node_id = i.node_id;

create or replace view v_patch_readiness as
select c.cdb_name,
       c.database_role,
       pg.patch_group_name,
       pg.target_ru,
       ps.scheduled_date,
       ps.completion_date,
       ps.status
  from ESTATE.cdb_patch_schedule ps
  join ESTATE.cdb c on c.cdb_id = ps.cdb_id
  join ESTATE.patch_group pg on pg.patch_group_id = ps.patch_group_id;

create or replace view v_dr_status as
select p.cdb_name primary_cdb,
       s.cdb_name standby_cdb,
       dr.protection_mode,
       dr.transport_status,
       dr.apply_status
  from ESTATE.dr_relationship dr
  join ESTATE.cdb p on p.cdb_id = dr.primary_cdb_id
  join ESTATE.cdb s on s.cdb_id = dr.standby_cdb_id;

create or replace view v_active_exceptions as
select coalesce(p.pdb_name, c.cdb_name) target_name,
       case when x.pdb_id is not null then 'PDB'
            when x.cdb_id is not null then 'CDB'
            else 'ESTATE'
       end target_type,
       x.exception_type,
       x.description,
       x.justification,
       x.approved_by,
       x.review_date
  from ESTATE.standard_exception x
  left join ESTATE.pdb p on p.pdb_id = x.pdb_id
  left join ESTATE.cdb c on c.cdb_id = x.cdb_id
 where x.active_flag = 'Y';
