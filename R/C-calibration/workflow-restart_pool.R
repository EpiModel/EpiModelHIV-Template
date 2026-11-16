## HPC Workflow: Restart Pool
##
## Make the restart pool (`path_to_restart_pool`) from the simulations a pool
## run left in `calib_dir` (`workflow-restart_point.R`), with
## `make_restart_pool.R`. No simulation is run. The swfcalib model function
## starts each simulation from a member of this pool (`make_model_fn(pool =
## TRUE)` in `swfcalib_config.R`), and so does the confirmation run at the end
## of `workflow-swfcalib.R`.
##
## Before deploying, check on the HPC that `calib_dir` holds the pool run the
## pool should come from (`sim__empty_scenario__*.rds` and
## `merged_tibbles/df__empty_scenario.rds`), and move any previous pool at
## `path_to_restart_pool` aside: the step stops if one exists.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("restart_pool", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/C-calibration/make_restart_pool.R",
    args = list(
      scenario_name = "empty_scenario",
      sims_dir = calib_dir,
      pool_dir = path_to_restart_pool,
      max_n = 500,
      # Adrien's rule: keep every simulation whose STI rates are at least half
      # their targets
      min_sti_frac = 0.5
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "01:00:00",
    "mem" = "32G",
    "mail-type" = "FAIL,END"
  )
)
