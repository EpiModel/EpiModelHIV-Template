## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in `param_msm`, with example of
## writing/debugging modules

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/E-intervention_explore/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("dplyr")
library("ggplot2")
theme_set(theme_light())
# load the local development version of the project
pkgload::load_all(EMHIVp_dir)

# Necessary files --------------------------------------------------------------
# set prep start to a low value to test the full model in a few steps
prep_start <- restart_time + 1 * year_steps
source("R/netsim_settings.R", local = TRUE)
orig <- readRDS(path_to_restart)

# Control settings
control <- control_msm(
  start               = restart_time,
  nsteps              = prep_start + 3 * year_steps,
  initialize.FUN      = reinit_msm
)

# Epidemic simulation
sim <- netsim(orig, param, init, control)

# Simulation exploration (tidyverse)
d_sim <- as_tibble(sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = prepCurr)) +
  geom_line()

# Run in debug mode, more details and examples here:
# https://github.com/EpiModel/EpiModeling/wiki/Writing-and-Debugging-EpiModel-Code
debugonce(hivtrans_msm)
sim <- netsim(orig, param, init, control)

# for advanced debugging: https://github.com/EpiModel/EpiModeling/wiki/Diagnostic-of-an-EpiModel-Module
