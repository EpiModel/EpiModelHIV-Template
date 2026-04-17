## 2. Netsim Module Development Script
##
## Run the model with your local development version of EpiModelHIV-p
## and debug modules interactively.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
# load the local development version of the project
load_local_EpiModelHIV()

source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R", local = TRUE)

# default theme for the plots
theme_set(theme_light())

# Process ----------------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

# Control settings
control <- control_msm(
  nsteps = year_steps * 4,
  # Always ncores = 1 with load_local_EpiModelHIV():
  # parallel workers load the installed package, not the dev version.
  ncores = 1
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

# Run in debug mode: steps into the module on the first call.
# See the README for more resources.
debugonce(hivtrans_msm)
sim <- netsim(est, param, init, control)
