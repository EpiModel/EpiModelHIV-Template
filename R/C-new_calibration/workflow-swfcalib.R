## HPC Workflow: swfcalib - Automated calibration
##
## Define a workflow to run the automated calibration process using swfcalib

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

batch_size <- 8
max_cores <- batch_size

# Process ----------------------------------------------------------------------

## Uncomment the calibration config to use
# source("./R/C-new_calibration/swfcalib_config_ballpark.R", local = TRUE)
# source("./R/C-new_calibration/swfcalib_config_pool1.R", local = TRUE)
source("./R/C-new_calibration/swfcalib_config_pool2.R", local = TRUE)

wf <- make_em_workflow("swfcalib", override = TRUE)

# Calibration step 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step1,
    args = list(
      calib_object = calib_object
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 8,
    "time" = "00:20:00",
    "mem-per-cpu" = "4G"
  )
)

# Calibration step 2
batch_numbers <- swfcalib:::get_batch_numbers(calib_object, batch_size)
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map(
    FUN = swfcalib::calibration_step2,
    batch_num = batch_numbers,
    setup_lines = hpc_node_setup,
    max_array_size = 500,
    MoreArgs = list(
      n_cores = batch_size,
      n_batches = max(batch_numbers),
      calib_object = calib_object
    )
  ),
  sbatch_opts = list(
    "cpus-per-task" = batch_size,
    "time" = "05:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Calibration step 3
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step3,
    args = list(
      calib_object = calib_object
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:20:00",
    "mem-per-cpu" = "8G",
    "mail-type" = "END"
  )
)

source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps              = calibration_end,
  start               = restart_time,
  initialize.FUN      = reinit_msm,
  verbose = FALSE
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_swfcalib_output(
    path_to_restart, param, init, control, calib_object,
    output_dir = calib_dir,
    n_rep = 64,
    n_cores = batch_size,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL",
    "cpus-per-task" = batch_size,
    "time" = "08:00:00",
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
    n_cores = batch_size,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = batch_size,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)
