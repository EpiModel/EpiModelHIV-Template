# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

# Necessary files
epistats <- readRDS("data/input/epistats.rds")
netstats <- readRDS("data/input/netstats.rds")
est      <- readRDS("data/input/netest.rds")

# Parameters
prep_start <- 2 * 52
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 26
)

# Initial conditions
init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 250,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = FALSE,
  truncate.el.cuml    = 0,
  # .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# Simulation and exploration ---------------------------------------------------
sim <- netsim(est, param, init, control)

d_sim <- as_tibble(sim)

glimpse(d_sim)


