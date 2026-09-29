## HPC Workflow: a new restart pool under the current parameters
##
## Restarts the 32 points of the current pool (`restart_pool.rds`, network
## offset 0) under the parameters of `model_parameters.csv` (commit f660508:
## the pool2 calibration values) and runs them 150 years, so that they reach
## the equilibrium of the new parameters (cycle 5: prevalence needs > 100
## years after a parameter change). The final states become the new pool,
## made locally with `3-choose_restart.R`-style tools from the raw files.
##
## Main run: one batch of 32 runs on 32 cores (recycling uses each point
## once), outputs in `data/run/new_pool/`.
## Replacement run (`extra_run <- TRUE`, 2026-09-29): 8 more runs, from pool
## points 1-8, to replace the 2 main runs that failed the STI filter
## (low syphilis). Outputs in `data/run/new_pool_extra/`.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-new_calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

extra_run <- TRUE

n_years   <- 150
if (extra_run) {
  wf_name   <- "new_pool_extra"
  max_cores <- 8
  pool_dir  <- paste0(run_dir, "new_pool_extra/")
} else {
  wf_name   <- "new_pool"
  max_cores <- 32
  pool_dir  <- paste0(run_dir, "new_pool/")
}

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
stopifnot(length(readRDS(path_to_restart)$run) == 32)

control <- control_msm(
  start          = restart_time,
  nsteps         = restart_time + n_years * year_steps,
  initialize.FUN = initialize.net,
  verbose        = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow(wf_name, override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control,
    scenarios_list = NULL,
    output_dir = pool_dir,
    n_rep = max_cores,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "08:00:00",
    "mem-per-cpu" = "5G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = pool_dir,
    output_dir = fs::path(pool_dir, "merged_tibbles"),
    steps_to_keep = Inf,
    cols = dplyr::everything(),
    n_cores = 8,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT,END",
    "cpus-per-task" = 8,
    "time" = "01:00:00",
    "mem-per-cpu" = "8G"
  )
)
