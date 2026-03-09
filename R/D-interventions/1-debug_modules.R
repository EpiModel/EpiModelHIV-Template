## 2. Netsim Module Development Script - post calibration
##
## Run `netsim` with estimated network models and interactively explore the
## content of the a simulation object. This script uses a restart point.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# load the local development version of the project
pkgload::load_all(EMHIVp_dir)

# Process ----------------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
control <- control_msm(
  start               = restart_time,
  nsteps              = restart_time + year_steps * 4,
  initialize.FUN      = reinit_msm,
  ncores = 1 # never use `ncores > 1` whith `pkgload::load_all(EMHIVp_dir)`
             # otherwise the parallel environment will load the installed version
             # of the package and not the dev one loaded by `load_all`.
)

# Read in the previously run model and inspect its content
orig <- readRDS(path_to_restart)
print(orig)
str(orig, max.level = 1)

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
