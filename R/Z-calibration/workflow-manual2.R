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
wf <- make_em_workflow("manual_calib_2", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios
# insert test values here
n_scenarios <- 2
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at                 = 1,
  part.ident.start    = prep_start,
  prep.start.prob_1   = rep(0.615625, n_scenarios), # 206
  prep.start.prob_2   = rep(0.766, n_scenarios), # 237
  prep.start.prob_3   = seq(0.77, 0.79, length.out = n_scenarios), # 332
  prep.discont.int_1  = rep(107.9573, n_scenarios),
  prep.discont.int_2  = prep.discont.int_1,
  prep.discont.int_3  = prep.discont.int_1
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control_calib_2,
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
