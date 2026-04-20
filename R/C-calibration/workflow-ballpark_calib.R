## HPC Workflow: Ballpark Calibration (Phase 1)
##
## Run the model from scratch with parameter grids to get all epidemics present
## and targets in the right ballpark. Results are assessed with
## `2-manual_calib_assess.R` and reused by `3-choose_restart.R` to create a
## restart point.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

max_cores <- 8

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("ballpark_calib", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios
# insert test values here
n_scenarios <- 10
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at = 1,
  # gono.uret.prob = seq(0.20, 0.22, length.out = n_scenarios),
  # chla.uret.prob = seq(0.2, 0.22, length.out = n_scenarios),
  # syph.prob = seq(0.115, 0.15, length.out = n_scenarios)
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est,
    param,
    init,
    control,
    # scenarios_list = scenarios_list,
    scenarios_list = NULL,
    output_dir = calib_dir,
    n_rep = 32,
    n_cores = max_cores,
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
    steps_to_keep = Inf, # keep everything
    cols = dplyr::everything(),
    n_cores = max_cores,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/C-calibration/process_calibs.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)
