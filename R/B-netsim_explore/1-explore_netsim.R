## 1. Netsim Interactive Exploration
##
## Run `netsim` with estimated network models and interactively explore the
## content of the a simulation object.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_explore/z-context.R")

# Process ----------------------------------------------------------------------

# set prep start to a low value to test the full model in a few steps
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)

# See full listing of parameters
# See ?param_msm for definitions
print(param)

# See the initialization object
print(init)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
control <- control_msm(
  nsteps = prep_start + year_steps * 3
)
print(control)

# Read in the previously estimated networks and inspect their content
est <- readRDS(path_to_est)

print(est$fit_main)
print(est$fit_casl)
print(est$fit_ooff)

# Epidemic simulation
sim <- netsim(est, param, init, control)

# Examine the model object output
print(sim)

# Plot outcomes
par(mar = c(3, 3, 2, 2), mgp = c(2, 1, 0))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")

# Convert to data frame
df <- as.data.frame(sim)
head(df)
tail(df)

## Run 2 simulations on 2 cores
## Note: this will not run generate a progress tracker in the console
control <- control_msm(
  nsteps = prep_start + year_steps * 3,
  nsims = 2, ncores = 2
)
print(control)

sim <- netsim(est, param, init, control)

# Simulation exploration (tidyverse)
library("dplyr")
library("ggplot2")
theme_set(theme_light())

d_sim <- as_tibble(sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = prepCurr, col = as.factor(sim))) +
  geom_line()
