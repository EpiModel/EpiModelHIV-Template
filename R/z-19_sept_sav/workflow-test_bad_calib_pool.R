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
  nsteps = 2 * calibration_end,
  start = restart_time,
  randomize.restart = TRUE,
  initialize.FUN = initialize.net,
  verbose = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("bad_pool_calib", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios
# insert test values here
scenarios_df <- tibble(
  .scenario.id = "bad_calib_pool",
  .at = 1,
  prep.start.rate_1 = 0.006187293,
  prep.start.rate_2 = 0.004409822,
  prep.start.rate_3 = 0.006681639,
  hiv.test.rate_1 = 0.0005234353,
  hiv.test.rate_2 = 0.001229486,
  hiv.test.rate_3 = 0.0008837888,
  tx.halt.rate_1 = 0.002225456,
  tx.halt.rate_2 = 0.002160703,
  tx.halt.rate_3 = 0.001402035,
  hiv.trans.scale_1 = 3.335358,
  hiv.trans.scale_2 = 0.6033294,
  hiv.trans.scale_3 = 0.4552222,
  gono.uret.prob = 0.2127404,
  chla.uret.prob = 0.1382087,
  syph.prob = 0.1351835,
  aids.off.tx.mort.rate = 0.0005601838,
  a.rate = 0.000421969
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart,
    param,
    init,
    control,
    scenarios_list = scenarios_list,
    output_dir = calib_dir,
    n_rep = 64,
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
