whenever sqlerror exit sql.sqlcode rollback

-- ESTATE grants only the read access required to build the application-facing layer.
-- WITH GRANT OPTION is required so ESTATE_AO can expose cross-schema views to APPESTATE.
grant read on project to ESTATE_AO with grant option;
grant read on environment to ESTATE_AO with grant option;
grant read on db_cluster to ESTATE_AO with grant option;
grant read on cluster_node to ESTATE_AO with grant option;
grant read on cdb to ESTATE_AO with grant option;
grant read on db_instance to ESTATE_AO with grant option;
grant read on pdb to ESTATE_AO with grant option;
grant read on pdb_project to ESTATE_AO with grant option;
grant read on db_account to ESTATE_AO with grant option;
grant read on account_project to ESTATE_AO with grant option;
grant read on db_service to ESTATE_AO with grant option;
grant read on service_instance_expectation to ESTATE_AO with grant option;
grant read on dr_relationship to ESTATE_AO with grant option;
grant read on patch_group to ESTATE_AO with grant option;
grant read on cdb_patch_schedule to ESTATE_AO with grant option;
grant read on standard_exception to ESTATE_AO with grant option;
