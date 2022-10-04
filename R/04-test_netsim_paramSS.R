
library("EpiModelHIV")

# Necessary files
epistats <- readRDS("data/input/epistats.rds")
netstats <- readRDS("data/input/netstats.rds")
est      <- readRDS("data/input/netest.rds")

# Parameters
# Uses example of data frame/spreadsheet for parameter input
# See ?param_msm for definitions
prep_start <- 2 * 52
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 26
)
param

# Initial conditions (default prevalence initialized in epistats)
# For models with bacterial STIs, these must be initialized here with non-zero values
init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 250,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = FALSE,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
print(control)

sim <- netsim(est, param, init, control)

# Examine the model object output
print(sim)

# Plot outcomes
plot(sim, y = "i.num")
plot(sim, y = "ir100")

# Convert to data frame
df <- as.data.frame(sim)
head(df)
