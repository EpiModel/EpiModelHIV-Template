## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in `param_msm`, with example of
## writing/debugging modules

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
source("R/utils-0_project_settings.R")

# Necessary files
epistats <- readRDS("data/intermediate/estimates/epistats-local.rds")
netstats <- readRDS("data/intermediate/estimates/netstats-local.rds")
est      <- readRDS("data/intermediate/estimates/netest-local.rds")

prep_start <- 52 * 2
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53
)

# See full listing of parameters
# See ?param_msm for definitions
print(param)

# Initial conditions (default prevalence initialized in epistats)
# For models with bacterial STIs, these must be initialized here with non-zero
# values
init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)

# Control settings
control <- control_msm(
  nsteps = 250,
  nsims = 1,
  ncores = 1
)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
print(control)

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
  nsteps = 250,
  nsims = 2,
  ncores = 2
)
sim <- netsim(est, param, init, control)

par(mfrow = c(2, 1))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")

## Example debugging of HIV transmission module in debug mode
# Start by sourcing local version of EpiModelHIV
pkgload::load_all("~/GitHub/EpiModelHIV-p")

# Rerun control settings (to source in local set of module functions)
# Note: debugging needs to run with 1 simulation on 1 core
control <- control_msm(
  nsteps = 250,
  nsims = 1,
  ncores = 1,
)

# Run in debug mode, more details and examples here:
# https://github.com/EpiModel/EpiModeling/wiki/Writing-and-Debugging-EpiModel-Code
debug(hivtrans_msm)
sim <- netsim(est, param, init, control)
undebug(hivtrans_msm)
