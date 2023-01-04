# Setup ------------------------------------------------------------------------
context <- "local"
source("R/utils-0_project_settings.R")

# Run the simulations ----------------------------------------------------------
library("EpiModelHIV")

# Necessary files
source("R/utils-default_inputs.R") # generate `path_to_restart`, `param`, `init`

# Controls
source("R/utils-targets.R")
control <- control_msm(
  start               = restart_time,
  nsteps              = prep_start + 52,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE
)

orig <- readRDS(path_to_restart)

# Simulation -------------------------------------------------------------------
sim <- netsim(orig, param, init, control)

# Interactiv exploration -------------------------------------------------------
d_sim <- as_tibble(sim)

glimpse(d_sim)
d_sim$prep_startat
d_sim$prep_ret1y
d_sim$prep_ret2y

library(ggplot2)

d_sim %>%
  filter(time > prep_start) %>%
  ggplot(aes(x = time, y = s_prep__B / s_prep_elig__B)) +
    geom_line()
