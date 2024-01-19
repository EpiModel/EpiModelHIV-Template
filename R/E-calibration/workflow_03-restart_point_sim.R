##
## Epidemic Model Parameter Calibration, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- "hpc"
max_cores <- 30

source("./R/utils-default_inputs.R") # make `path_to_est`, `param` and `init`
source("./R/utils-hpc_configs.R") # creates `hpc_configs`

# ------------------------------------------------------------------------------

# Workflow creation
wf <- create_workflow(
  wf_name = "restart_point",
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

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  # .tracker.list       = calibration_trackers,
  # .checkpoint.dir     = "temp/cp_calib",
  # .checkpoint.clear   = TRUE,
  # .checkpoint.steps   = 15 * 52,
  verbose             = FALSE
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = NULL,
    n_rep = 120,
    n_cores = max_cores,
    libraries = c("EpiModelHIV", "networkLite"),
    output_dir = "data/intermediate/calibration",
    save_pattern = "restart", # more data is required to allow restarting
    max_array_size = 999,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem" = 0
  )
)

# Process calibrations ---------------------------------------------------------
# produce a data frame with the calibration targets for each scenario
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
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "4G"
  )
)

# Calibration Plots ------------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/23-restart_point_process_plots.R",
    args = list(
      context = "hpc",
      ncores = 10
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "END"
  )
)

# Send the workflow folder to the <HPC> and run it
#
# $ scp -r ./workflows/restart_point <HPC>:<project_dir>/workflows/
#
# on the HPC:
# $ ./workflows/model_calibration/start_workflow.sh

# Once the worfklow is finished download the data from the HPC
#
# $ scp -r <HPC>:<project_dir>/data/intermediate/calibration/assessments_raw.rds ./data/intermediate/calibration/
# $ scp -r <HPC>:<project_dir>/data/intermediate/calibration/calibration_plots.rds ./data/intermediate/calibration/
#
# and analyse them locally using: "./R/22-restart_point_choose.R" and set
# `context` to "hpc"
#
# and save the plots locally using: "./R/24-restart_point_make_plots.R" and set
# `context` to "hpc"
