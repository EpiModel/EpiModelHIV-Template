library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

calib_object <- readRDS("./data/calib/calib_object.rds")

calib_scenario <- EpiModelHPC:::make_calibrated_scenario(calib_object)

source("R/00-project_settings.R")
epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")
path_to_est <- "data/intermediate/estimates/netest.rds"

param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53,
  .param.updater.list = list(
    # High PrEP intake for the first year; go back to normal to get to 15%
    list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
    list(at = prep_start + 52, param = list(prep.start.prob = function(x) x / 2))
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
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  # .checkpoint.dir     = "temp/cp_calib",
  # .checkpoint.clear   = TRUE,
  # .checkpoint.steps   = 15 * 52,
  verbose             = TRUE
)

netsim_swfcalib_output(
  path_to_est, param, init, control,
  calib_object = calib_object,
  output_dir = "data/intermediate/calibration",
  libraries = "EpiModelHIV",
  n_rep = 3,
  n_cores = 2
)

