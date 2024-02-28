## HPC Workflow: Epidemic Model Scenarios Playground
##
## Define a workflow to run `netsim` via the scenario API on the HPC

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

max_cores <- 8

# Process ----------------------------------------------------------------------
wf <- make_em_workflow("networks", override = TRUE)

# Necessary files
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = prep_start + year_steps * 3
)

# Workflow creation
wf <- make_em_workflow("scenarios", override = TRUE)

# Define test scenarios
scenarios_df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = 1,
  hiv.test.rate_1 = c(0.004, 0.005),
  hiv.test.rate_2 = c(0.004, 0.005),
  hiv.test.rate_3 = c(0.007, 0.008)
)
# or read them from CSV
# scenarios_df <- readr::read_csv("./data/input/scenarios.csv")

scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = scenarios_list,
    output_dir = scenarios_dir,
    save_pattern = "all",
    n_rep = 32,
    n_cores = max_cores,
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
      sim_dir = scenarios_dir,
      output_dir = fs::path(scenarios_dir, "merged_tibbles"),
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
