library("slurmworkflow")
library("EpiModelHPC")
source("R/00-project_settings.R")

hpc_configs <- swf_configs_rsph(
  partition = "epimodel",
  mail_user = mail_user
)

scenarios.df <- tibble(
  .scenario.id = as.character(seq_len(5)),
  .at = 1,
  ugc.prob = seq(0.3225, 0.3275, length.out = 5), # best 0.325
  rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob = seq(0.29, 0.294, length.out = 5), # best 0.291
  rct.prob = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

# we can impose a lot of I/O things (folder structure)
# we can impose a "calibration process fn" in script "specific name"
#   we can have "local versions" of the simple workflows that guarantee it will
#   work on HPC
wf <- create_calibration_workflow(
  output_dir = "data/intermediate/calibration",
  n_rep = 150,
  max_array_size = 999, # could be set in `hpc_configs`
  max_core = 30         # could be set in `hpc_configs`
)
