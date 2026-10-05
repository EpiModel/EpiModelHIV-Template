## HPC Workflow: swfcalib - HIV transmission scales to new-diagnosis incidence
##
## Runs the calibration defined in `swfcalib_config_dx.R` (two passes of 128
## runs, 70 years from the restart pool), then 64 validation runs with the
## calibrated values. Batches of 32 runs on 32 cores.
##
## Outputs in their own directories: `data/run/swfcalib_dx/` (calibration)
## and `data/run/calibration_dx/` (validation runs).

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-new_calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

batch_size <- 32
max_cores <- batch_size
valid_dir <- paste0(run_dir, "calibration_dx/")

# Process ----------------------------------------------------------------------
source("./R/C-new_calibration/swfcalib_config_dx.R", local = TRUE)

wf <- make_em_workflow("swfcalib_dx", override = TRUE)

# Calibration step 1: process results, decide, propose
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step1,
    args = list(calib_object = calib_object),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 8,
    "time" = "00:30:00",
    "mem-per-cpu" = "4G"
  )
)

# Calibration step 2: the runs
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
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Calibration step 3: wrap up, loop back to step 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step3,
    args = list(calib_object = calib_object),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:20:00",
    "mem-per-cpu" = "8G",
    "mail-type" = "END"
  )
)

# Validation runs with the calibrated values
source("R/netsim_settings.R", local = TRUE)
control <- control_msm(
  nsteps = calibration_end,
  start = restart_time,
  randomize.restart = TRUE,
  initialize.FUN = initialize.net,
  # forked workers share the restart pool; multisession would copy 2.4 GB
  # to each of the 32 workers and run out of memory (2026-09-30)
  future.use.plan = future::tweak("multicore", workers = batch_size),
  verbose = FALSE
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_swfcalib_output(
    path_to_restart, param, init, control, calib_object,
    output_dir = valid_dir,
    n_rep = 64,
    n_cores = batch_size,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL",
    "cpus-per-task" = batch_size,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = valid_dir,
    output_dir = fs::path(valid_dir, "merged_tibbles"),
    steps_to_keep = Inf,
    cols = dplyr::everything(),
    n_cores = 8,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = 8,
    "time" = "01:00:00",
    "mem-per-cpu" = "8G"
  )
)
