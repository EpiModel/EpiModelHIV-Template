##
## Epidemic Model Parameter Calibration, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
library("EpiModelHIV")
library("dplyr")

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/B-netsim_local/z-context.R", local = TRUE)

source("./R/hpc_configs.R")
max_cores <- 8

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
#
# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("manual_calib_1", override = TRUE)

# Using scenarios --------------------------------------------------------------

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control_calib_1,
    scenarios_list = NULL,
    output_dir = calib_dir,
    libraries = c("EpiModelHIV"),
    n_rep = 512,
    n_cores = max_cores,
    save_pattern = "all",
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
      steps_to_keep = year_steps * 3, # keep the last 3 years
      cols = dplyr::everything(),
      n_cores = max_cores,
      setup_lines = hpc_node_setup
    ),
    sbatch_opts = list(
      "mail-type" = "END",
      "cpus-per-task" = max_cores,
      "time" = "02:00:00",
      "mem-per-cpu" = "5G"
    )
)

# add the creation of the assessment

# Do the selection directly on the HPC?
