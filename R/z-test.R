# Scratchpad for interactive testing before integration in a script

library("slurmworkflow")
library("EpiModelHPC")
source("R/utils-0_project_settings.R")

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
  nsteps              = 10,
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
  .scenario.id = as.character(seq_len(2)),
  .at = 1,
  ugc.prob = seq(0.3225, 0.3275, length.out = 2), # best 0.325
  rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob = seq(0.29, 0.294, length.out = 2), # best 0.291
  rct.prob = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

EpiModelHPC::netsim_scenarios(
  x = est,
  param = param,
  init = init,
  control = control,
  scenarios_list = scenarios.list,
  n_rep = 4,
  n_cores = 2,
  output_dir = "./data/intermediate/calibration",
  libraries = "EpiModelHIV",
  save_pattern = c("simple", "el.cuml")
)

sim <- readRDS("./data/intermediate/calibration/sim__1__1.rds")
names(sim)

as.data.frame(sim)

sim$el.cuml



