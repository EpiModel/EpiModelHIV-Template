# Libraries --------------------------------------------------------------------
library("EpiModelHIV")
library("EpiModelHPC")
library("slurmworkflow")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- "hpc"

source("./R/utils-default_inputs.R")

n_sims <- 400
step1_n_cores <- 10
step2_n_cores <- 40

source("./R/auto_cal_config.R")

# Workflow ---------------------------------------------------------------------
source("./R/utils-hpc_configs.R")

wf <- create_workflow(
  wf_name = "auto_calib",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Update RENV on the HPC
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = current_git_branch,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

# Calibration step 1
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/wf_step1.R",
    args = list(
      n_cores = step1_n_cores,
      calib_object = calib_object
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = step1_n_cores,
    "time" = "00:20:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "FAIL"
  )
)

# Calibration step 2
batch_numbers <- swfcalib:::get_batch_numbers(calib_object, step2_n_cores)
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map_script(
    r_script = "R/wf_step2.R",
    batch_num = batch_numbers,
    setup_lines = hpc_configs$r_loader,
    max_array_size = 400,
    MoreArgs = list(
      n_cores = step2_n_cores,
      n_batches = max(batch_numbers),
      calib_object = calib_object
    )
  ),
  sbatch_opts = list(
    "cpus-per-task" = step2_n_cores,
    "time" = "05:00:00",
    "mem" = "0",
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
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:20:00",
    "mem-per-cpu" = "8G",
    "mail-type" = "FAIL"
  )
)

# Calibration test -------------------------------------------------------------
max_cores <- 20

# Controls
source("./R/utils-targets.R")
control <- control_msm(
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_swfcalib_output(
    path_to_est, param, init, control,
    calib_object = calib_object,
    output_dir = calib_dir,
    libraries = "EpiModelHIV",
    n_rep = 500,
    n_cores = 20,
    max_array_size = 999,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem" = "0" # special: all mem on node
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/11-calibration_process.R",
    args = list(
      context = "hpc",
      ncores = 15
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = 15,
    "time" = "04:00:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "END"
  )
)
