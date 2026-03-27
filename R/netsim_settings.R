## Default settings for `netsim`
##
## This script should not be run directly. But `sourced` from other scripts
## using the `netsim` function.
##
## Requires:
##   - `context` (from z-context.R)
##   -  paths from shared_variables.R
## Creates:  `param`, `init`, `path_to_est`, `path_to_restart`

# Load network statistics and estimation outputs from Chapter A
epistats <- readRDS(fs::path(est_dir, paste0("epistats-", context, ".rds")))
netstats <- readRDS(fs::path(est_dir, paste0("netstats-", context, ".rds")))
path_to_est <- fs::path(est_dir, paste0("netest-", context, ".rds"))
path_to_restart <- fs::path(est_dir, paste0("restart-", context, ".rds"))

params_df <- read.csv(fs::path(input_dir, "model_parameters.csv")) |>
  dplyr::select(param, value, type)

# `netsim` Parameters
param <- param.net(
  data.frame.params   = params_df,
  netstats            = netstats,
  epistats            = epistats,
  prep.start          = prep_start,
  riskh.start         = prep_start - year_steps
)

# Initial conditions (default prevalence initialized in epistats).
# For models without bacterial STIs, these must be initialized
# here with non-zero values.
init <- init_msm(
  prev.gono.rect = 0.1,
  prev.gono.uret = 0.1,
  prev.chla.rect = 0.1,
  prev.chla.uret = 0.1,
  prev.syph      = 0.1
)

# Flags to now weather each disease is enabled
has_sti <- c(
  gono = init$prev.gono.rect > 0 | init$prev.gono.uret > 0,
  chla = init$prev.chla.rect > 0 | init$prev.chla.uret > 0,
  syph = init$prev.syph > 0
)
