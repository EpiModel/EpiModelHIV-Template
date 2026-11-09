# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

scenario_name <- c("empty_scenario", "default")[1]

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("make_restart_pool", override = TRUE)

source("R/netsim_settings.R", local = TRUE)

wf <- slurmworkflow::add_workflow_step(
  wf_summary = wf,
  step_tmpl = slurmworkflow::step_tmpl_do_call_script(
    r_script = "R/Z-calibration/make_restart_pool.R",
    args = list(
      scenario_name = scenario_name,
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
