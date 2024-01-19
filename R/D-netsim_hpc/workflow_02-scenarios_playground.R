##
## Epidemic Model Scenarios Playground, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- "hpc"
max_cores <- 8

source("./R/utils-default_inputs.R") # make `path_to_est`, `param` and `init`
source("./R/utils-hpc_configs.R") # creates `hpc_configs`

# ------------------------------------------------------------------------------

# Workflow creation
wf <- create_workflow(
  wf_name = "scenarios_playground",
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
source("./R/utils-targets.R")
control <- control_msm(
  nsteps              = 52 * 20, # run for 20 years
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  verbose             = FALSE
)

scenarios_df <- readr::read_csv("./data/input/scenarios.csv")
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = scenarios_list,
    output_dir = "./data/intermediate/scenarios",
    libraries = "EpiModelHIV",
    save_pattern = "full",
    n_rep = 120,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Process calibrations
#
# see the documentation of both these templates
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
      sim_dir = "data/intermediate/scenarios",
      output_dir = "data/intermediate/scenarios/merged_tibbles",
      steps_to_keep = 52 * 12, # keep the last 12 years
      cols = dplyr::everything(),
      n_cores = 8,
      setup_lines = hpc_configs$r_loader
    ),
    sbatch_opts = list(
      "mail-type" = "END",
      "cpus-per-task" = 8,
      "time" = "02:00:00",
      "mem-per-cpu" = "5G"
    )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios(
      sim_dir = "data/intermediate/scenarios",
      output_dir = "data/intermediate/scenarios/merged_netsim",
      truncate.at = control$nsteps - 52 * 12,
      n_cores = 8,
      setup_lines = hpc_configs$r_loader
    ),
    sbatch_opts = list(
      "mail-type" = "END",
      "cpus-per-task" = 8,
      "time" = "02:00:00",
      "mem-per-cpu" = "5G"
    )
)

# Send the workflow folder to the <HPC> and run it
#
# $ scp -r ./workflows/model_calibration <HPC>:<project_dir>/workflows/
#
# on the HPC:
# $ ./workflows/model_calibration/start_workflow.sh

# Once the worfklow is finished download the data from the HPC
#
# $ scp -r <HPC>:<project_dir>/data/intermediate/calibration/assessments.rds ./data/intermediate/calibration/
#
# and analyse them locally using: "./R/12-calibration_eval.R"
