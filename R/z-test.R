pkgload::load_all("../../EpiModelHPC.git/main")
source("R/00-project_settings.R")

# Run the simulations ----------------------------------------------------------
library(EpiModelHIV)

epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")

param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53,
  hiv.test.rate = c(0.004508235, 0.003748965, 0.005791135),
  tx.init.rate = c(0.2972737, 0.3674605, 0.3575724),
  tx.halt.partial.rate = c(0.005324598, 0.005001534, 0.003334693),
  hiv.trans.scale = c(1.713511, 0.266574, 0.1783712),
  .param.updater.list = list(
    # High PrEP intake for the first year; go back to normal to get to 15%
    list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
    list(at = prep_start + 52, param = list(prep.start.prob = function(x) x / 2))
  )
)

init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 20,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

scenarios.df <- tibble(
  .scenario.id = c("0", "1"),
  .at = 1,
  prep.start.prob_1 = seq(0.28, 0.31, length.out = 2),
  prep.start.prob_2 = prep.start.prob_1,
  prep.start.prob_3 = prep.start.prob_1,
  prep.discont.rate_1 = rep(0.0064, 2),
  prep.discont.rate_2 = prep.discont.rate_1,
  prep.discont.rate_3 = prep.discont.rate_1
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)


save(est, param, init, control, scenarios.list, file = "ss.rda")

load("ss.rda")
pkgload::load_all("../../EpiModelHPC.git/main")
netsim_scenarios(
  est, param, init, control,
  scenarios_list = scenarios.list,
  n_rep = 4,
  n_cores = 2,
  output_dir = "data/intermediate/calibration",
  libraries = "dplyr"
)
