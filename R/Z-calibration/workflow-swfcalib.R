## HPC Workflow: swfcalib - Automated calibration
##
## Define a workflow to run the automated calibration process using swfcalib

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

batch_size <- 8

# Process ----------------------------------------------------------------------

## Uncomment the calibration config to use
source("./R/Z-calibration/autocalib-config_1.R")
#source("./R/Z-calibration/autocalib-config_2.R")

wf <- make_em_workflow("swfcalib", override = TRUE)

# Calibration step 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step1,
    args = list(
      n_cores = 8,
      calib_object = calib_object
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 8,
    "time" = "00:20:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "FAIL"
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
    "mem-per-cpu" = "5G",
    "mail-type" = "FAIL"
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
