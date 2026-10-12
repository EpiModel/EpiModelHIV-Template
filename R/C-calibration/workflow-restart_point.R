## HPC Workflow: Restart Point
##
## Run a pool of replications of the model with the current parameters, from
## scratch to `calibration_end`, and save the one closest to the calibration
## targets as the restart point (`path_to_restart`).
##
## Run it after the parameters change: once calibration has converged and its
## values are in "data/input/model_parameters.csv", and again whenever
## attributes or parameters change, since a restart point carries the state of
## the model that produced it.
##
## Before deploying, clear the previous pool from `calib_dir` on the HPC
## (`sim__empty_scenario__*.rds` and `merged_tibbles/df__empty_scenario.rds`).
## Leftover files would be merged with the new ones.

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

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("restart_point", override = TRUE)

# Run the pool of candidate simulations. With no scenarios, the output files
# are named for the empty scenario, which is what `3-choose_restart.R` reads.
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = NULL,
    output_dir = calib_dir,
    n_rep = 500,
    n_cores = max_cores,
    max_array_size = 1000,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Merge the simulations into one tibble
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

# Pick the simulation closest to the targets and save it as the restart point
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/C-calibration/3-choose_restart.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Summarize how close the pool is to the targets ("calib_assess.csv")
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/C-calibration/process_calibs.R",
    args = list(hpc_context = TRUE, n_cores = max_cores),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)
