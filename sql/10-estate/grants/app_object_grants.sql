whenever sqlerror exit sql.sqlcode rollback

-- ESTATE grants only the object access required to build the application-facing layer.
grant select on project to ESTATE_AO;
grant select on environment to ESTATE_AO;
grant select on db_cluster to ESTATE_AO;
grant select on cluster_node to ESTATE_AO;
grant select on database_inventory to ESTATE_AO;
grant select on database_project to ESTATE_AO;
grant select on db_account to ESTATE_AO;
grant select on account_project to ESTATE_AO;
grant select on db_service to ESTATE_AO;
grant select on service_node_expectation to ESTATE_AO;
grant select on dr_relationship to ESTATE_AO;
grant select on patch_group to ESTATE_AO;
grant select on database_patch_schedule to ESTATE_AO;
grant select on standard_exception to ESTATE_AO;
