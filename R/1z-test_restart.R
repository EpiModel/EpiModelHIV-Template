# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
source("R/000-project_settings.R")

# Necessary files
epistats <- readRDS(fs::path(estimates_dir, "epistats.rds"))
netstats <- readRDS(fs::path(estimates_dir, "netstats.rds"))
orig     <- readRDS(fs::path(estimates_dir, "restart.rds"))

prep_start <- calib_end + 55

# Parameters
param <- param.net(
  data.frame.params = readr::read_csv(fs::path(inputs_dir, "params.csv")),
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

# Initial conditions
init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  start               = calib_end + 1,
  nsteps              = prep_start + 52 * 4,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# Simulation and exploration ---------------------------------------------------
sim <- netsim(orig, param, init, control)

d_sim <- as_tibble(sim)

glimpse(d_sim)
d_sim$prep_startat___ALL
d_sim$prep_ret1y___ALL
d_sim$prep_ret2y___ALL


library(ggplot2)

d_sim %>%
  filter(time > prep_start) %>%
  ggplot(aes(x = time, y = s_prep___B / s_prep_elig___B)) +
    geom_line()
