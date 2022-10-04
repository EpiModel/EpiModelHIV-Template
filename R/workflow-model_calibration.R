##
## Epidemic Model Parameter Calibration, HPC setup
##

# Setup ------------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")
source("R/00-project_settings.R")

hpc_configs <- swf_configs_rsph(
  partition = "epimodel",
  mail_user = mail_user
)

max_cores <- 30

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "model_calibration",
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
library(EpiModelHIV)

epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")


param <- param.net(
  data.frame.params = read.csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53,
  .param.updater.list = list(
    # High PrEP intake for the first year; go back to normal to get to 15%
    list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
    list(at = prep_start + 52, param = list(prep.start.prob = function(x) x/2))
  )
)

init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = calib_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE,
  .checkpoint.dir     = "temp/cp_calib",
  .checkpoint.clear   = TRUE,
  .checkpoint.steps   = 15 * 52
)

# insert test values here
scenarios.df <- tibble(
  .scenario.id = as.character(seq_len(5)),
  .at = 1,
  ugc.prob = seq(0.3225, 0.3275, length.out = 5), # best 0.325
  rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob = seq(0.29, 0.294, length.out = 5), # best 0.291
  rct.prob = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    est, param, init, control,
    scenarios_list = scenarios.list,
    output_dir = "data/intermediate/calibration",
    libraries = "EpiModelHIV",
    n_rep = 150,
    n_cores = max_cores,
    max_array_size = 999,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem" = "0" # special: all mem on node
  )
)

# Process calibrations ---------------------------------------------------------
# produce a data frame with the calibration targets for each scenario
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/wscript-calibration_process.R",
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
