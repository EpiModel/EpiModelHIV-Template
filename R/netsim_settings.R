if (!context %in% c("local", "hpc")) {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

epistats <- readRDS(fs::path(est_dir, paste0("epistats-", context, ".rds")))
netstats <- readRDS(fs::path(est_dir, paste0("netstats-", context, ".rds")))
path_to_est <- fs::path(est_dir, paste0("netest-", context, ".rds"))
path_to_restart <- fs::path(est_dir, paste0("restart-", context, ".rds"))

# `netsim` Parameters
param <- param.net(
  data.frame.params   = read.csv("data/input/params.csv"),
  netstats            = netstats,
  epistats            = epistats,
  prep.start          = prep_start,
  riskh.start         = prep_start - year_steps - 1
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


# defaul control object - post-calibration
control_restart <- control_msm(
  start               = restart_time,
  nsteps              = intervention_end,
  initialize.FUN      = reinit_msm
)

control_calib_1 <- control_msm(
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  .tracker.list       = EpiModelHIV::make_calibration_trackers,
  verbose             = FALSE
)

control_calib_2 <- control_msm(
  start               = restart_time,
  nsteps              = intervention_start,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = EpiModelHIV::make_calibration_trackers,
  verbose             = FALSE
)
