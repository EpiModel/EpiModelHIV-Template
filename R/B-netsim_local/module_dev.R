## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in `param_msm`, with example of
## writing/debugging modules

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("dplyr")
library("ggplot2")
theme_set(theme_light())
# load the local development version of the project
pkgload::load_all(EMHIVp_dir)

# Necessary files --------------------------------------------------------------
# set prep start to a low value to test the full model in a few steps
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

# Control settings
control$nsteps <- prep_start + year_steps * 3
control$verbose <- TRUE

# Epidemic simulation
sim <- netsim(est, param, init, control)

# Simulation exploration (tidyverse)
d_sim <- as_tibble(sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = prepCurr)) +
  geom_line()

# Run in debug mode, more details and examples here:
# https://github.com/EpiModel/EpiModeling/wiki/Writing-and-Debugging-EpiModel-Code
debug(hivtrans_msm)
sim <- netsim(est, param, init, control)
undebug(hivtrans_msm)

# for advanced debugging: https://github.com/EpiModel/EpiModeling/wiki/Diagnostic-of-an-EpiModel-Module
