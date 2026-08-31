-- ============================================================================
-- Oracle Estate Operations
-- Operational State Seed Data
--
-- Purpose:
--   Populate mutable operational conditions separately from the reference
--   topology defined in 01_reference_topology.sql.
--
-- This file intentionally introduces a small number of realistic conditions
-- for operational reporting and validation while leaving most of the estate
-- healthy.
--
-- Seeded scenarios:
--   1. Service placement mismatch
--   2. Patch level / scheduling exception
--   3. Degraded Data Guard condition
--   4. Approved standards exception
--   5. Cross-project account ownership
-- ============================================================================

set define off
set serveroutput on
whenever sqlerror exit sql.sqlcode rollback

prompt
prompt === Seeding operational state ===
prompt

prompt === Service placement scenario ===

-- HR Reporting TEST service.
-- Expected placement: RAC instances 1 and 2.
-- Observed placement: RAC instances 1 and 3.
-- This creates one intentional service-placement mismatch.

merge into ESTATE.db_service target
using (
    select p.pdb_id,
           'HR_REPORTING_TST' service_name,
           'Y' enabled_flag
      from ESTATE.pdb p
      join ESTATE.cdb c
        on c.cdb_id = p.cdb_id
     where c.db_unique_name = 'NHR002E'
       and p.pdb_name = 'T001'
) source
on (
    target.pdb_id = source.pdb_id
    and target.service_name = source.service_name
)
when matched then
    update set target.enabled_flag = source.enabled_flag
when not matched then
    insert (pdb_id, service_name, enabled_flag)
    values (source.pdb_id, source.service_name, source.enabled_flag);

merge into ESTATE.service_instance_expectation target
using (
    select s.service_id,
           i.instance_id,
           case when i.instance_number in (1,2) then 'Y' else 'N' end expected_flag,
           case when i.instance_number in (1,3) then 'Y' else 'N' end observed_flag
      from ESTATE.db_service s
      join ESTATE.pdb p
        on p.pdb_id = s.pdb_id
      join ESTATE.cdb c
        on c.cdb_id = p.cdb_id
      join ESTATE.db_instance i
        on i.cdb_id = c.cdb_id
     where c.db_unique_name = 'NHR002E'
       and p.pdb_name = 'T001'
       and s.service_name = 'HR_REPORTING_TST'
) source
on (
    target.service_id = source.service_id
    and target.instance_id = source.instance_id
)
when matched then
    update set
        target.expected_flag = source.expected_flag,
        target.observed_flag = source.observed_flag
when not matched then
    insert (
        service_id,
        instance_id,
        expected_flag,
        observed_flag
    )
    values (
        source.service_id,
        source.instance_id,
        source.expected_flag,
        source.observed_flag
    );

prompt === Patch scheduling scenario ===

-- Common patch target for the fictional estate.
merge into ESTATE.patch_group target
using (
    select '2026-Q3-RU' patch_group_name,
           '19.28' target_ru,
           'Quarterly maintenance window' maintenance_window
      from dual
) source
on (
    target.patch_group_name = source.patch_group_name
)
when matched then
    update set
        target.target_ru = source.target_ru,
        target.maintenance_window = source.maintenance_window
when not matched then
    insert (
        patch_group_name,
        target_ru,
        maintenance_window
    )
    values (
        source.patch_group_name,
        source.target_ru,
        source.maintenance_window
    );

-- Most CDBs are ready for the target RU.
merge into ESTATE.cdb_patch_schedule target
using (
    select c.cdb_id,
           pg.patch_group_id,
           date '2026-09-12' scheduled_date,
           case
               when c.db_unique_name = 'NHR003E' then 'DEFERRED'
               else 'READY'
           end status
      from ESTATE.cdb c
      cross join ESTATE.patch_group pg
     where pg.patch_group_name = '2026-Q3-RU'
) source
on (
    target.cdb_id = source.cdb_id
    and target.patch_group_id = source.patch_group_id
)
when matched then
    update set
        target.scheduled_date = source.scheduled_date,
        target.completion_date = null,
        target.status = source.status
when not matched then
    insert (
        cdb_id,
        patch_group_id,
        scheduled_date,
        completion_date,
        status
    )
    values (
        source.cdb_id,
        source.patch_group_id,
        source.scheduled_date,
        null,
        source.status
    );

prompt === Data Guard operational scenario ===

-- Introduce one intentional degraded Data Guard condition.
-- NHR003 remains a valid primary/standby relationship, but apply is lagging.

update ESTATE.dr_relationship dr
   set dr.transport_status = 'VALID',
       dr.apply_status     = 'LAGGING'
 where dr.primary_cdb_id = (
           select c.cdb_id
             from ESTATE.cdb c
            where c.db_unique_name = 'NHR003E'
       )
   and dr.standby_cdb_id = (
           select c.cdb_id
             from ESTATE.cdb c
            where c.db_unique_name = 'NHR003W'
       );

prompt === Approved standards exception ===

-- One intentional, approved exception to the normal estate standard.
merge into ESTATE.standard_exception target
using (
    select p.pdb_id,
           'NAMING_STANDARD' exception_type,
           'Customer Portal TEST retains a legacy-compatible database object naming convention.' description,
           'Temporary compatibility requirement while dependent application components are remediated.' justification,
           'Database Engineering' approved_by,
           date '2026-10-15' review_date,
           'Y' active_flag
      from ESTATE.pdb p
      join ESTATE.cdb c
        on c.cdb_id = p.cdb_id
     where c.db_unique_name = 'NHR002E'
       and p.pdb_name = 'T003'
) source
on (
    target.pdb_id = source.pdb_id
    and target.exception_type = source.exception_type
)
when matched then
    update set
        target.description = source.description,
        target.justification = source.justification,
        target.approved_by = source.approved_by,
        target.review_date = source.review_date,
        target.active_flag = source.active_flag
when not matched then
    insert (
        pdb_id,
        exception_type,
        description,
        justification,
        approved_by,
        review_date,
        active_flag
    )
    values (
        source.pdb_id,
        source.exception_type,
        source.description,
        source.justification,
        source.approved_by,
        source.review_date,
        source.active_flag
    );

prompt === Cross-project account ownership ===

-- Demonstrate that account ownership is independent of PDB ownership.
-- T001 is the HR Reporting TEST PDB, but this integration account is owned
-- by the Finance Analytics project.

merge into ESTATE.db_account target
using (
    select p.pdb_id,
           'FIN_RPT_INTEGRATION' account_name,
           'SERVICE' account_type,
           'OPEN' account_status,
           date '2026-07-15' last_password_change,
           'Finance Analytics integration account hosted in the HR Reporting TEST PDB.' description
      from ESTATE.pdb p
      join ESTATE.cdb c
        on c.cdb_id = p.cdb_id
     where c.db_unique_name = 'NHR002E'
       and p.pdb_name = 'T001'
) source
on (
    target.pdb_id = source.pdb_id
    and target.account_name = source.account_name
)
when matched then
    update set
        target.account_type = source.account_type,
        target.account_status = source.account_status,
        target.last_password_change = source.last_password_change,
        target.description = source.description
when not matched then
    insert (
        pdb_id,
        account_name,
        account_type,
        account_status,
        last_password_change,
        description
    )
    values (
        source.pdb_id,
        source.account_name,
        source.account_type,
        source.account_status,
        source.last_password_change,
        source.description
    );

merge into ESTATE.account_project target
using (
    select a.account_id,
           pr.project_id,
           'Y' primary_flag
      from ESTATE.db_account a
      join ESTATE.pdb p
        on p.pdb_id = a.pdb_id
      join ESTATE.cdb c
        on c.cdb_id = p.cdb_id
      cross join ESTATE.project pr
     where c.db_unique_name = 'NHR002E'
       and p.pdb_name = 'T001'
       and a.account_name = 'FIN_RPT_INTEGRATION'
       and pr.project_code = '004'
) source
on (
    target.account_id = source.account_id
    and target.project_id = source.project_id
)
when matched then
    update set target.primary_flag = source.primary_flag
when not matched then
    insert (
        account_id,
        project_id,
        primary_flag
    )
    values (
        source.account_id,
        source.project_id,
        source.primary_flag
    );

prompt
prompt === Operational state seed complete ===

commit;
