## 2. Netsim Module Development Script
##
## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in data/input/model_parameters.xlsx`, with example of
## writing/debugging modules

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(ggplot2)

source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R", local = TRUE)

# load the local development version of the project
pkgload::load_all(EMHIVp_dir)

# default theme for the plots
theme_set(theme_light())

# Process ----------------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

# Control settings
control <- control_msm(
  nsteps = year_steps * 4,
  ncores = 1 # never use `ncores > 1` whith `pkgload::load_all(EMHIVp_dir)`
             # otherwise the parallel environment will load the installed version
             # of the package and not the dev one loaded by `load_all`.
)

# Epidemic simulation
sim <- netsim(est, param, init, control)

# Simulation exploration (tidyverse)
d_sim <- as_tibble(sim)

# See all tracked values
glimpse(tail(d_sim))

d_sim <- d_sim |>
  mutate(
    prep_cov = prep / prep.indic
  )

ggplot(d_sim, aes(x = time, y = prep_cov)) +
  geom_line()

# Run in debug mode, more details and examples here:
# https://github.com/EpiModel/EpiModeling/wiki/Writing-and-Debugging-EpiModel-Code
debugonce(hivtrans_msm)
sim <- netsim(est, param, init, control)

# for advanced debugging: https://github.com/EpiModel/EpiModeling/wiki/Diagnostic-of-an-EpiModel-Module
