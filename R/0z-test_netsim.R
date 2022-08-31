# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
source("R/000-project_settings.R")


# Necessary files
epistats <- readRDS(fs::path(estimates_dir, "epistats.rds"))
netstats <- readRDS(fs::path(estimates_dir, "netstats.rds"))
est      <- readRDS(fs::path(estimates_dir, "netest.rds"))

# Parameters
prep_start <- 65 * 52
param <- param.net(
  data.frame.params = readr::read_csv(fs::path(inputs_dir, "params.csv")),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53
)

# Initial conditions
init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 25,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# Simulation and exploration ---------------------------------------------------
sim <- netsim(est, param, init, control)

d_sim <- as_tibble(sim)

glimpse(d_sim)


