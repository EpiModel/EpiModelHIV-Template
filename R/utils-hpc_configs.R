# Must be sourced **AFTER** "./R/utils-0_project_settings.R"

hpc_configs <- EpiModelHPC::swf_configs_rsph(
  partition = "epimodel",
  r_version = "4.2.1",
  mail_user = mail_user
)
#
# hpc_configs <- EpiModelHPC::swf_configs_hyak(
#   hpc = "mox",
#   partition = "ckpt",
#   r_version = "4.1.2",
#   mail_user = mail_user
# )

# hpc_configs <- EpiModelHPC::swf_configs_hyak(
#   hpc = "klone",
#   partition = "ckpt",
#   r_version = "4.1.1",
#   mail_user = mail_user
# )
