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
  nsteps              = calibration_end,
  start               = restart_time,
  initialize.FUN      = reinit_msm,
  randomize.restart   = TRUE,
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
  prep.start.rate_1 = 0.0059217,
  prep.start.rate_2 = 0.004542306,
  prep.start.rate_3 = 0.006757837,
  hiv.test.rate_1 = 0.0006724602,
  hiv.test.rate_2 = 0.0009920079,
  hiv.test.rate_3 = 0.0006740063,
  tx.halt.rate_1 = 0.002236491,
  tx.halt.rate_2 = 0.002060115,
  tx.halt.rate_3 = 0.001382714,
  hiv.trans.scale_1 = 3.439541,
  hiv.trans.scale_2 = 0.6153605,
  hiv.trans.scale_3 = 0.4557934,
  gono.uret.prob = 0.2058703,
  chla.uret.prob = 0.1374851,
  syph.prob = 0.1315037,
  aids.off.tx.mort.rate = 0.00053713,
  a.rate = 0.00042235
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    "./data/run/estimates/restart_pool.rds",
    param,
    init,
    control,
    scenarios_list = scenarios_list,
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
    args = list(hpc_context = TRUE, n_cores = max_cores),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)
