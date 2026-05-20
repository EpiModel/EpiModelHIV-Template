## HPC Workflow: Restart Calibration (Phase 3 — manual)
##
## Test parameter adjustments starting from the restart point. More stable than
## ballpark calibration since the population is simulation-born rather than
## completely synthetic. When better parameters are found, re-create the restart
## point before moving to swfcalib.

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
  verbose = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("restart_calib", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios
# insert test values here
n_scenarios <- 1
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at = 1,
  hiv.test.rate_1 = param$hiv.test.rate[[1]] * 0.475, # 0.6
  hiv.test.rate_2 = param$hiv.test.rate[[2]] * 0.7,
  hiv.test.rate_3 = param$hiv.test.rate[[3]] * 0.625,
  tx.halt.rate_1 = param$tx.halt.rate[[1]] * 0.850,
  tx.halt.rate_2 = param$tx.halt.rate[[2]] * 0.925,
  tx.halt.rate_3 = param$tx.halt.rate[[3]] * 1.089,
  gono.uret.prob = param$gono.uret.prob * 1.055,
  chla.uret.prob = param$chla.uret.prob * 1.035,
  syph.prob = param$syph.prob * 0.98,
  prep.start.rate_1 = param$prep.start.rate[[1]] * 1.11,
  prep.start.rate_2 = param$prep.start.rate[[2]] * 1.03,
  prep.start.rate_3 = param$prep.start.rate[[3]] * 1.02,
  aids.off.tx.mort.rate = param$aids.off.tx.mort.rate * 1.075,
  hiv.trans.scale_1 = param$hiv.trans.scale[[1]] * 1.05,
  hiv.trans.scale_2 = param$hiv.trans.scale[[2]] * 1.1,
  hiv.trans.scale_3 = param$hiv.trans.scale[[3]] * 1.05
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control,
    # scenarios_list = scenarios_list,
    scenarios_list = NULL,
    output_dir = calib_dir,
    n_rep = 128,
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
