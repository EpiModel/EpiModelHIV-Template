## Default settings for `netsim`
##
## This script should not be run directly. But `sourced` from other scripts
## using the `netsim` function

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
  prep.start          = 0,
  riskh.start         = 0
)

# Initial conditions (default prevalence initialized in epistats)
# For models without bacterial STIs, these must be initialized here
# with non-zero values
init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1,
  prev.syph = 0.1
)
