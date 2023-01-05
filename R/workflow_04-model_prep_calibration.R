##
## Epidemic Model Parameter Calibration, HPC setup
##

# Setup ------------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
source("R/utils-0_project_settings.R")

hpc_configs <- swf_configs_rsph(
  partition = "epimodel",
  r_version = "4.2.1",
  git_version = "2.35.1",
  mail_user = mail_user
)

max_cores <- 30

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "prep_calibration",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Update RENV on the HPC -------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = current_git_branch,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

# Run the simulations ----------------------------------------------------------
library("EpiModelHIV")

context <- "hpc"
source("R/utils-default_inputs.R") # generate `path_to_est`, `param` and `init`

# Controls
source("R/utils-targets.R")
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
n_scenarios <- 5
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at                 = 1,
  part.ident.start    = prep_start,
  prep.start.prob_1   = rep(0.615625, n_scenarios), # 206
  prep.start.prob_2   = rep(0.766, n_scenarios), # 237
  prep.start.prob_3   = seq(0.77, 0.79, length.out = n_scenarios), # 332
  prep.discont.rate_1 = rep(0.00688, n_scenarios),
  prep.discont.rate_2 = prep.discont.rate_1,
  prep.discont.rate_3 = prep.discont.rate_1
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

# Process calibrations ---------------------------------------------------------
# produce a data frame with the calibration targets for each scenario
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/11-calibration_process.R",
    args = list(
      ncores = 15,
      nsteps = 52
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

