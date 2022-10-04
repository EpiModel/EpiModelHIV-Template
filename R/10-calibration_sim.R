##
## 10. Epidemic Model Parameter Calibration, Local simulation runs
##

# Setup ------------------------------------------------------------------------
source("R/00-project_settings.R")

max_cores <- 2

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
  nsims               = max_cores,
  ncores              = max_cores,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# insert test values here
scenarios.df <- tibble(
  # mandatory columns
  .scenario.id = as.character(seq_len(5)),
  .at          = 1,
  # parameters to test columns
  ugc.prob     = seq(0.3225, 0.3275, length.out = 5), # best 0.325
  rgc.prob     = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob     = seq(0.29, 0.294, length.out = 5), # best 0.291
  rct.prob     = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

for (i in seq_along(scenarios_list)) {
  start_time <- Sys.time()

  param_sc <- EpiModel::use_scenario(param, scenario[[i]])

  print(paste0("Starting simulation for scenario: ", scenario[["id"]]))
  sim <- netsim(est, param_sc, init, control)

  file_name <- paste0("sim__", scenario[["id"]], "__", batch_num, ".rds")

  print(paste0("Saving simulation in file: ", file_name))
  saveRDS(sim, fs::path(output_dir, file_name))

  print("Done in: ")
  print(Sys.time() - start_time)
}
