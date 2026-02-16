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

source("R/netsim_settings.R", local = TRUE)

# See full listing of parameters
# See data/input/model_parameters.xlsx for definitions
print(param)

# See the initialization object
print(init)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
control <- control_msm(
  nsteps = year_steps * 4
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
plot(sim, y = "hiv.inf", main = "Number of Infected with HIV")
plot(sim, y = "syph.inf", main = "Number of Infected with Syphilis")

# Convert to data frame
df <- as.data.frame(sim)
head(df)
tail(df)

## Run 2 simulations on 2 cores
## Note: this will not run generate a progress tracker in the console
control <- control_msm(
  nsteps = year_steps * 4,
  nsims = 2,
  ncores = 2
)
print(control)

sim <- netsim(est, param, init, control)

# Simulation exploration (tidyverse)
library("dplyr")
library("ggplot2")
theme_set(theme_light())

d_sim <- as_tibble(sim)
d_sim <- mutate_calibration_targets(d_sim)
glimpse(d_sim)

ggplot(d_sim, aes(x = time, y = cc.dx.B, col = as.factor(sim))) +
  geom_line()

ggplot(d_sim, aes(x = time, y = prep, col = as.factor(sim))) +
  geom_line()

d_sim <- as.epi.data.frame(d_sim)
plot(d_sim, y = "cc.dx.B", main = "Proportion of Diagnosed (Black)")