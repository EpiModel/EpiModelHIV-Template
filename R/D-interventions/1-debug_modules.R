## 1. Module Development — Post Calibration
##
## Same as B-model_dev/2-debug_modules.R but starting from the calibrated
## restart point (produced by Chapter C). Use this to test module changes
## with calibrated parameters before running intervention scenarios.

# Restart R before running this script
#
# Load the local development version of EpiModelHIV-p
load_local_EpiModelHIV()
library(dplyr)
library(ggplot2)
theme_set(theme_light())

# Setup ------------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)

# Start from the restart point (end of calibration) and run 4 years forward.
# reinit_msm re-initializes the simulation state from the saved restart object.
control <- control_msm(
  start          = restart_time,
  nsteps         = restart_time + year_steps * 4,
  initialize.FUN = reinit_msm,
  # Always ncores = 1 with load_all(): parallel workers load the installed
  # package, not the dev version.
  ncores         = 1
)

# Inspect the restart point
orig <- readRDS(path_to_restart)
print(orig)
str(orig, max.level = 1)

# Epidemic simulation
sim <- netsim(orig, param, init, control)

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
