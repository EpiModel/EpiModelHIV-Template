if (!context %in% c("local", "hpc")) {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

epistats <- readRDS(paste0(est_dir, "epistats-", context, ".rds"))
netstats <- readRDS(paste0(est_dir, "netstats-", context, ".rds"))
path_to_est <- paste0(est_dir, "netest-", context, ".rds")
path_to_restart <- paste0(est_dir, "restart-", context, ".rds")

# `netsim` Parameters
param <- param.net(
  data.frame.params   = read.csv("data/input/params.csv"),
  netstats            = netstats,
  epistats            = epistats,
  prep.start          = prep_start,
  riskh.start         = prep_start - 53
)

# Initial conditions (default prevalence initialized in epistats)
# For models without bacterial STIs, these must be initialized here
# with non-zero values
init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)
