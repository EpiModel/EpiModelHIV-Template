## HPC Workflow: end-to-end test of the HPC procedure
##
## A deliberately tiny run (16 runs x 2 years from the restart pool) to check
## the whole cycle: build, upload, start, monitor, download. It writes only to
## its own directory, `data/run/hpc_test/`, so it cannot overwrite the outputs
## of other workflows.

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
test_dir  <- paste0(run_dir, "hpc_test/")

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings: 2 years after the restart
control <- control_msm(
  nsteps              = restart_time + 2 * year_steps,
  start               = restart_time,
  initialize.FUN      = initialize.net,
  verbose             = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("hpc_test", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control,
    scenarios_list = NULL,
    output_dir = test_dir,
    n_rep = 16,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "01:00:00",
    "mem-per-cpu" = "5G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = test_dir,
    output_dir = fs::path(test_dir, "merged_tibbles"),
    steps_to_keep = Inf,
    cols = dplyr::everything(),
    n_cores = max_cores,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT,END",
    "cpus-per-task" = max_cores,
    "time" = "00:30:00",
    "mem-per-cpu" = "5G"
  )
)
