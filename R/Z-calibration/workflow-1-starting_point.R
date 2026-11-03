# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

max_cores <- 8

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end,
  inst.resim = "exact",
  # start = restart_time,
  # initialize.FUN = initialize.net,
  verbose = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("merck_start", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    # path_to_restart_pool,
    path_to_est,
    param,
    init,
    control,
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
    "time" = "06:00:00",   # 70-year baseline run, safety margin over 4h
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
    "mem-per-cpu" = "5G",
    "mail-type" = "END"
  )
)

wf <- slurmworkflow::add_workflow_step(
  wf_summary = wf,
  step_tmpl = slurmworkflow::step_tmpl_do_call_script(
    r_script = "R/Z-calibration/make_restart_pool.R",
    args = list(
      scenario_name = "empty_scenario",
      sims_dir = calib_dir,
      pool_dir = path_to_restart_pool,
      max_n = 500
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mem" = "8G",
    "cpus-per-task" = 1,
    "time" = "00:60:00",
    "mail-type" = "FAIL,END"
  )
)
