whenever sqlerror exit sql.sqlcode rollback

-- APPESTATE receives only the application-facing views, not direct ESTATE table access.
grant select on v_estate_status to APPESTATE;
grant select on v_cdb_instance_status to APPESTATE;
grant select on v_pdb_ownership to APPESTATE;
grant select on v_account_ownership to APPESTATE;
grant select on v_service_compliance to APPESTATE;
grant select on v_patch_readiness to APPESTATE;
grant select on v_dr_status to APPESTATE;
grant select on v_active_exceptions to APPESTATE;
