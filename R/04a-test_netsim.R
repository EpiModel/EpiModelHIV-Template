
## Example interactive epidemic simulation run script with basic parameterization
##    and all parameters defined in `param_msm`, with example of writing/debugging modules

library("EpiModelHIV")

# Necessary files
epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")

param <- param_msm(
  netstats               = netstats,
  epistats               = epistats,
  a.rate                 = 0.00049,
  hiv.test.rate          = c(0.00385, 0.00380, 0.00690),
  tx.init.rate           = c(0.1775, 0.190, 0.2521),
  tx.halt.partial.rate   = c(0.0062, 0.0055, 0.0031),
  tx.reinit.partial.rate = c(0.00255, 0.00255, 0.00255),
  hiv.trans.scale        = c(2.44, 0.424, 0.270),
  riskh.start            = 1,
  prep.start             = 26,
  prep.start.prob        = rep(0.66, 3)
)

# See full listing of parameters
# See ?param_msm for definitions
print(param)

# Initial conditions (default prevalence initialized in epistats)
# For models with bacterial STIs, these must be initialized here with non-zero values
init <- init_msm()

# Control settings
control <- control_msm(
  nsteps = 250,
  nsims = 1,
  ncores = 1,
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


## Run 5 simulations on 5 cores
## Note: this will not run generate a progress tracker in the console
control <- control_msm(
  nsteps = 250,
  nsims = 5,
  ncores = 5,
)
sim <- netsim(est, param, init, control)

par(mfrow = c(2, 1))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")

## Example debugging of HIV transmission module in debug mode
# Start by sourcing local version of EpiModelHIV
pkgload::load_all("~/git/EpiModelHIV-p")

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
