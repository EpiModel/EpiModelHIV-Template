## HPC Workflow: Restart Point
##
## Define a workflow to run a few hundred replications of the default paramater
## and choose the best restart point

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

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end,
  .tracker.list = EpiModelHIV::make_calibration_trackers()
)

wf <- make_em_workflow("restart_point", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = NULL,
    output_dir = calib_dir,
    save_pattern = "all",
    n_rep = 512,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL",
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
      steps_to_keep = Inf,
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
    r_script = "R/Z-calibration/choose_restart.R",
    args = list(hpc_context = TRUE),
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
    r_script = "R/Z-calibration/process_calib_plots.R",
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
