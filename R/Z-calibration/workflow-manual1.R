##
## Epidemic Model Parameter Calibration, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
library("EpiModelHIV")
library("dplyr")

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/B-netsim_local/z-context.R", local = TRUE)

source("./R/hpc_configs.R")
max_cores <- 8

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
#
# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("manual_calib_1", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios
# insert test values here
n_scenarios <- 2
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at = 1,
  ugc.prob = seq(0.3225, 0.3275, length.out = n_scenarios), # best 0.325
  rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob = seq(0.29, 0.294, length.out = n_scenarios), # best 0.291
  rct.prob = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control_calib_1,
    scenarios_list = scenarios_list,
    output_dir = calib_dir,
    libraries = c("EpiModelHIV"),
    n_rep = 120,
    n_cores = max_cores,
    save_pattern = "simple",
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Process calibrations
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
      sim_dir = calib_dir,
      output_dir = fs::path(calib_dir, "merged_tibbles"),
      steps_to_keep = year_steps * 3, # keep the last 3 years
      cols = dplyr::everything(),
      n_cores = max_cores,
      setup_lines = hpc_node_setup
    ),
    sbatch_opts = list(
      "mail-type" = "END",
      "cpus-per-task" = max_cores,
      "time" = "02:00:00",
      "mem-per-cpu" = "5G"
    )
)

# add the creation of the assessment
