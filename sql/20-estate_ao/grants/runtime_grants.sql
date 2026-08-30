whenever sqlerror exit sql.sqlcode rollback

-- APPESTATE receives only read access to application-facing views, not direct ESTATE table access.
grant read on v_estate_status to APPESTATE;
grant read on v_cdb_instance_status to APPESTATE;
grant read on v_pdb_ownership to APPESTATE;
grant read on v_account_ownership to APPESTATE;
grant read on v_service_compliance to APPESTATE;
grant read on v_patch_readiness to APPESTATE;
grant read on v_dr_status to APPESTATE;
grant read on v_active_exceptions to APPESTATE;
