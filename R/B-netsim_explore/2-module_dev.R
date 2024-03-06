## 2. Netsim Module Development Script
##
## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in `param_msm`, with example of
## writing/debugging modules

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(ggplot2)

source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_explore/z-context.R")

# load the local development version of the project
pkgload::load_all(EMHIVp_dir)

# default theme for the plots
theme_set(theme_light())

# Process ----------------------------------------------------------------------

# set prep start to a low value to test the full model in a few steps
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

# Control settings
control <- control_msm(
  nsteps = prep_start + year_steps * 3
)

# Epidemic simulation
sim <- netsim(est, param, init, control)

# Simulation exploration (tidyverse)
d_sim <- as_tibble(sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = prepCurr)) +
  geom_line()

# Run in debug mode, more details and examples here:
# https://github.com/EpiModel/EpiModeling/wiki/Writing-and-Debugging-EpiModel-Code
debugonce(hivtrans_msm)
sim <- netsim(est, param, init, control)

# for advanced debugging: https://github.com/EpiModel/EpiModeling/wiki/Diagnostic-of-an-EpiModel-Module
