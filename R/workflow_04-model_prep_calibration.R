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
  wf_name = "prep_calibration",
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
  start               = restart_time,
  nsteps              = intervention_start,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# insert test values here
n_scenarios <- 2
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at                 = 1,
  part.ident.start    = prep_start,
  prep.start.prob_1   = rep(0.615625, n_scenarios), # 206
  prep.start.prob_2   = rep(0.766, n_scenarios), # 237
  prep.start.prob_3   = seq(0.77, 0.79, length.out = n_scenarios), # 332
  prep.discont.int_1  = rep(107.9573, n_scenarios),
  prep.discont.int_2  = prep.discont.int_1,
  prep.discont.int_3  = prep.discont.int_1
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control,
    scenarios_list = scenarios_list,
    output_dir = "data/intermediate/calibration",
    libraries = "EpiModelHIV",
    save_pattern = "simple",
    n_rep = 120,
    n_cores = max_cores,
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

# Process calibrations
#
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
    "mem-per-cpu" = "4G",
    "mail-type" = "END"
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
