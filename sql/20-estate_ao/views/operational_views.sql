whenever sqlerror exit sql.sqlcode rollback

create or replace view v_estate_status as
select d.database_id,
       d.database_name,
       e.environment_code,
       d.architecture_type,
       d.database_role,
       d.oracle_version,
       c.cluster_name,
       d.active_flag
  from ESTATE.database_inventory d
  join ESTATE.environment e on e.environment_id = d.environment_id
  left join ESTATE.db_cluster c on c.cluster_id = d.cluster_id;

create or replace view v_database_ownership as
select d.database_name,
       e.environment_code,
       p.project_code,
       p.application_name,
       p.owner_name,
       p.sme_name,
       p.manager_name,
       dp.primary_flag
  from ESTATE.database_inventory d
  join ESTATE.environment e on e.environment_id = d.environment_id
  join ESTATE.database_project dp on dp.database_id = d.database_id
  join ESTATE.project p on p.project_id = dp.project_id;

create or replace view v_account_ownership as
select d.database_name,
       a.account_name,
       a.account_type,
       a.account_status,
       a.last_password_change,
       p.project_code,
       p.application_name,
       p.owner_name,
       ap.primary_flag
  from ESTATE.db_account a
  join ESTATE.database_inventory d on d.database_id = a.database_id
  left join ESTATE.account_project ap on ap.account_id = a.account_id
  left join ESTATE.project p on p.project_id = ap.project_id;

create or replace view v_service_compliance as
select d.database_name,
       s.service_name,
       n.node_name,
       sne.expected_flag,
       sne.observed_flag,
       case when sne.expected_flag = sne.observed_flag then 'COMPLIANT' else 'MISMATCH' end compliance_status
  from ESTATE.db_service s
  join ESTATE.database_inventory d on d.database_id = s.database_id
  join ESTATE.service_node_expectation sne on sne.service_id = s.service_id
  join ESTATE.cluster_node n on n.node_id = sne.node_id;

create or replace view v_patch_readiness as
select d.database_name,
       e.environment_code,
       pg.patch_group_name,
       pg.target_ru,
       ps.scheduled_date,
       ps.completion_date,
       ps.status
  from ESTATE.database_patch_schedule ps
  join ESTATE.database_inventory d on d.database_id = ps.database_id
  join ESTATE.environment e on e.environment_id = d.environment_id
  join ESTATE.patch_group pg on pg.patch_group_id = ps.patch_group_id;

create or replace view v_dr_status as
select p.database_name primary_database,
       s.database_name standby_database,
       dr.protection_mode,
       dr.transport_status,
       dr.apply_status
  from ESTATE.dr_relationship dr
  join ESTATE.database_inventory p on p.database_id = dr.primary_database_id
  join ESTATE.database_inventory s on s.database_id = dr.standby_database_id;

create or replace view v_active_exceptions as
select d.database_name,
       x.exception_type,
       x.description,
       x.justification,
       x.approved_by,
       x.review_date
  from ESTATE.standard_exception x
  left join ESTATE.database_inventory d on d.database_id = x.database_id
 where x.active_flag = 'Y';
