whenever sqlerror exit sql.sqlcode rollback

prompt === Seeding projects and environments ===

insert into ESTATE.project
    (project_code, application_name, description, owner_name, sme_name, manager_name)
values
    ('001', 'HR Reporting', 'Enterprise workforce reporting and analytics.', 'Alex Morgan', 'Jordan Lee', 'Taylor Brooks');

insert into ESTATE.project
    (project_code, application_name, description, owner_name, sme_name, manager_name)
values
    ('002', 'Order Management', 'Order intake, fulfillment coordination, and status services.', 'Casey Reed', 'Morgan Patel', 'Taylor Brooks');

insert into ESTATE.project
    (project_code, application_name, description, owner_name, sme_name, manager_name)
values
    ('003', 'Customer Portal', 'Customer-facing account and service portal.', 'Riley Chen', 'Jamie Ortiz', 'Avery King');

insert into ESTATE.project
    (project_code, application_name, description, owner_name, sme_name, manager_name)
values
    ('004', 'Finance Analytics', 'Financial reporting, reconciliation, and analytics platform.', 'Sam Rivera', 'Drew Parker', 'Avery King');

insert into ESTATE.project
    (project_code, application_name, description, owner_name, sme_name, manager_name)
values
    ('005', 'Warehouse Operations', 'Warehouse execution and operational reporting services.', 'Cameron Blake', 'Robin Shah', 'Taylor Brooks');

insert into ESTATE.environment (environment_code, display_name, sort_order) values ('DEV',  'Development',              10);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('QA',   'Quality Assurance',        20);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('TEST', 'Pre-production Test',      30);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('UAT',  'User Acceptance Testing',  40);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('PERF', 'Performance Testing',      50);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('PROD', 'Production',               60);
insert into ESTATE.environment (environment_code, display_name, sort_order) values ('DR',   'Disaster Recovery',         70);

prompt === Seeding RAC clusters and nodes ===

insert into ESTATE.db_cluster (cluster_name, platform_type, description)
values ('NONPROD-EAST', 'EXADATA', 'East-region RAC infrastructure for non-production workloads.');

insert into ESTATE.db_cluster (cluster_name, platform_type, description)
values ('NONPROD-WEST', 'EXADATA', 'West-region RAC infrastructure for production-like non-production peers.');

insert into ESTATE.db_cluster (cluster_name, platform_type, description)
values ('PROD-EAST', 'EXADATA', 'East-region production RAC infrastructure.');

insert into ESTATE.db_cluster (cluster_name, platform_type, description)
values ('PROD-WEST', 'EXADATA', 'West-region production RAC infrastructure.');

-- Four-node RAC footprints allow Test and UAT to mirror production topology.
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-e01' from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-e02' from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-e03' from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-e04' from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';

insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-w01' from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-w02' from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-w03' from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'nonprod-w04' from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';

insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-e01' from ESTATE.db_cluster where cluster_name = 'PROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-e02' from ESTATE.db_cluster where cluster_name = 'PROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-e03' from ESTATE.db_cluster where cluster_name = 'PROD-EAST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-e04' from ESTATE.db_cluster where cluster_name = 'PROD-EAST';

insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-w01' from ESTATE.db_cluster where cluster_name = 'PROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-w02' from ESTATE.db_cluster where cluster_name = 'PROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-w03' from ESTATE.db_cluster where cluster_name = 'PROD-WEST';
insert into ESTATE.cluster_node (cluster_id, node_name)
select cluster_id, 'prod-w04' from ESTATE.db_cluster where cluster_name = 'PROD-WEST';

prompt === Seeding CDBs ===

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'NHR001E', 'NHR001E', cluster_id, 'RAC', 'NONE', '19c',
       'General Development and QA CDB.'
  from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'NHR002E', 'NHR002E', cluster_id, 'RAC', 'PRIMARY', '19c',
       'East Test peer; currently PRIMARY.'
  from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'NHR002W', 'NHR002W', cluster_id, 'RAC', 'STANDBY', '19c',
       'West Test peer; currently STANDBY.'
  from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'NHR003E', 'NHR003E', cluster_id, 'RAC', 'PRIMARY', '19c',
       'East Acceptance/UAT peer; currently PRIMARY.'
  from ESTATE.db_cluster where cluster_name = 'NONPROD-EAST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'NHR003W', 'NHR003W', cluster_id, 'RAC', 'STANDBY', '19c',
       'West Acceptance/UAT peer; currently STANDBY.'
  from ESTATE.db_cluster where cluster_name = 'NONPROD-WEST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'PHR001E', 'PHR001E', cluster_id, 'RAC', 'PRIMARY', '19c',
       'East production peer; currently PRIMARY.'
  from ESTATE.db_cluster where cluster_name = 'PROD-EAST';

insert into ESTATE.cdb
    (cdb_name, db_unique_name, cluster_id, architecture_type, database_role, oracle_version, description)
select 'PHR001W', 'PHR001W', cluster_id, 'RAC', 'STANDBY', '19c',
       'West production peer; currently STANDBY.'
  from ESTATE.db_cluster where cluster_name = 'PROD-WEST';

prompt === Seeding RAC instances ===

-- Each CDB has one instance per node of its hosting RAC cluster.
begin
    for c in (
        select c.cdb_id, c.cdb_name, c.database_role, cl.cluster_name
          from ESTATE.cdb c
          join ESTATE.db_cluster cl on cl.cluster_id = c.cluster_id
    ) loop
        for n in (
            select node_id,
                   row_number() over (order by node_name) as instance_number
              from ESTATE.cluster_node
             where cluster_id = (select cluster_id from ESTATE.db_cluster where cluster_name = c.cluster_name)
        ) loop
            insert into ESTATE.db_instance
                (cdb_id, node_id, instance_name, instance_number, status)
            values
                (c.cdb_id,
                 n.node_id,
                 c.cdb_name || n.instance_number,
                 n.instance_number,
                 case when c.database_role = 'STANDBY' then 'MOUNTED' else 'OPEN' end);
        end loop;
    end loop;
end;
/

prompt === Seeding PDB inventory ===

-- Development and QA share NHR001E.
insert into ESTATE.pdb (cdb_id, environment_id, pdb_name, open_mode, description)
select c.cdb_id, e.environment_id, x.pdb_name, 'READ WRITE', x.description
  from ESTATE.cdb c
  cross join ESTATE.environment e
  cross join (
      select 'D001' pdb_name, 'HR Reporting DEV' description from dual union all
      select 'D002', 'Order Management DEV' from dual union all
      select 'D003', 'Customer Portal DEV' from dual union all
      select 'D004', 'Finance Analytics DEV' from dual union all
      select 'D005', 'Warehouse Operations DEV' from dual
  ) x
 where c.cdb_name = 'NHR001E'
   and e.environment_code = 'DEV';

insert into ESTATE.pdb (cdb_id, environment_id, pdb_name, open_mode, description)
select c.cdb_id, e.environment_id, x.pdb_name, 'READ WRITE', x.description
  from ESTATE.cdb c
  cross join ESTATE.environment e
  cross join (
      select 'Q001' pdb_name, 'HR Reporting QA' description from dual union all
      select 'Q002', 'Order Management QA' from dual union all
      select 'Q003', 'Customer Portal QA' from dual union all
      select 'Q004', 'Finance Analytics QA' from dual union all
      select 'Q005', 'Warehouse Operations QA' from dual
  ) x
 where c.cdb_name = 'NHR001E'
   and e.environment_code = 'QA';

-- Test is isolated and mirrored across East and West.
insert into ESTATE.pdb (cdb_id, environment_id, pdb_name, open_mode, description)
select c.cdb_id,
       e.environment_id,
       x.pdb_name,
       case when c.database_role = 'PRIMARY' then 'READ WRITE' else 'MOUNTED' end,
       x.description
  from ESTATE.cdb c
  cross join ESTATE.environment e
  cross join (
      select 'T001' pdb_name, 'HR Reporting TEST' description from dual union all
      select 'T002', 'Order Management TEST' from dual union all
      select 'T003', 'Customer Portal TEST' from dual union all
      select 'T004', 'Finance Analytics TEST' from dual union all
      select 'T005', 'Warehouse Operations TEST' from dual
  ) x
 where c.cdb_name in ('NHR002E','NHR002W')
   and e.environment_code = 'TEST';

-- UAT is independently isolated and mirrored across East and West.
insert into ESTATE.pdb (cdb_id, environment_id, pdb_name, open_mode, description)
select c.cdb_id,
       e.environment_id,
       x.pdb_name,
       case when c.database_role = 'PRIMARY' then 'READ WRITE' else 'MOUNTED' end,
       x.description
  from ESTATE.cdb c
  cross join ESTATE.environment e
  cross join (
      select 'A001' pdb_name, 'HR Reporting UAT' description from dual union all
      select 'A002', 'Order Management UAT' from dual union all
      select 'A003', 'Customer Portal UAT' from dual union all
      select 'A004', 'Finance Analytics UAT' from dual union all
      select 'A005', 'Warehouse Operations UAT' from dual
  ) x
 where c.cdb_name in ('NHR003E','NHR003W')
   and e.environment_code = 'UAT';

-- Production is isolated on dedicated infrastructure and mirrored East/West.
insert into ESTATE.pdb (cdb_id, environment_id, pdb_name, open_mode, description)
select c.cdb_id,
       e.environment_id,
       x.pdb_name,
       case when c.database_role = 'PRIMARY' then 'READ WRITE' else 'MOUNTED' end,
       x.description
  from ESTATE.cdb c
  cross join ESTATE.environment e
  cross join (
      select 'P001' pdb_name, 'HR Reporting PROD' description from dual union all
      select 'P002', 'Order Management PROD' from dual union all
      select 'P003', 'Customer Portal PROD' from dual union all
      select 'P004', 'Finance Analytics PROD' from dual union all
      select 'P005', 'Warehouse Operations PROD' from dual
  ) x
 where c.cdb_name in ('PHR001E','PHR001W')
   and e.environment_code = 'PROD';

prompt === Mapping PDBs to primary projects ===

insert into ESTATE.pdb_project (pdb_id, project_id, primary_flag)
select p.pdb_id, pr.project_id, 'Y'
  from ESTATE.pdb p
  join ESTATE.project pr
    on pr.project_code = substr(p.pdb_name, 2, 3);

prompt === Seeding Data Guard relationships ===

insert into ESTATE.dr_relationship
    (primary_cdb_id, standby_cdb_id, protection_mode, transport_status, apply_status)
select p.cdb_id, s.cdb_id, 'MAXIMUM PERFORMANCE', 'VALID', 'APPLYING'
  from ESTATE.cdb p
  cross join ESTATE.cdb s
 where p.cdb_name = 'NHR002E'
   and s.cdb_name = 'NHR002W';

insert into ESTATE.dr_relationship
    (primary_cdb_id, standby_cdb_id, protection_mode, transport_status, apply_status)
select p.cdb_id, s.cdb_id, 'MAXIMUM PERFORMANCE', 'VALID', 'APPLYING'
  from ESTATE.cdb p
  cross join ESTATE.cdb s
 where p.cdb_name = 'NHR003E'
   and s.cdb_name = 'NHR003W';

insert into ESTATE.dr_relationship
    (primary_cdb_id, standby_cdb_id, protection_mode, transport_status, apply_status)
select p.cdb_id, s.cdb_id, 'MAXIMUM PERFORMANCE', 'VALID', 'APPLYING'
  from ESTATE.cdb p
  cross join ESTATE.cdb s
 where p.cdb_name = 'PHR001E'
   and s.cdb_name = 'PHR001W';

commit;

prompt === Reference topology seed complete ===
