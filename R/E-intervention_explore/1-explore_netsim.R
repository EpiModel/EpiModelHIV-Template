## 1. Intervention Scenarios: Interactive Exploration
##
## Run `netsim` with estimated network models and interactively explore the
## content of the a simulation object. This script uses a restart point.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/E-intervention_explore/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# set prep start to a low value to test the full model in a few steps
prep_start <- restart_time + 1 * year_steps
source("R/netsim_settings.R", local = TRUE)

# See full listing of parameters
# See ?param_msm for definitions
print(param)

# See the initialization object
print(init)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
control <- control_msm(
  start               = restart_time,
  nsteps              = prep_start + 3 * year_steps,
  initialize.FUN      = reinit_msm
)
print(control)

# Read in the previously run model and inspect its content
orig <- readRDS(path_to_restart)
print(orig)
str(orig, max.level = 1)

# Epidemic simulation
sim <- netsim(orig, param, init, control)

# Examine the model object output
print(sim)

# Plot outcomes
# par(mar = c(3, 3, 2, 2), mgp = c(2, 1, 0))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")

# Simulation exploration (tidyverse)
library("dplyr")
library("ggplot2")
theme_set(theme_light())

d_sim <- as_tibble(sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = prepCurr, col = as.factor(sim))) +
  geom_line()

ggplot(d_sim, aes(x = time, y = num, col = as.factor(sim))) +
  geom_line()
