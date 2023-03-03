calibration1_fun <- function(proposal) {
  # Libraries ------------------------------------------------------------------
  library("EpiModelHIV")
  library("dplyr")

  # Settings -------------------------------------------------------------------
  source("./R/utils-0_project_settings.R")
  context <- "hpc"

  # Inputs ---------------------------------------------------------------------
  source("./R/utils-default_inputs.R", local = TRUE)
  est <- readRDS(path_to_est)

  source("R/utils-targets.R")
  control <- control_msm(
    nsteps              = calibration_end,
    nsims               = 1,
    ncores              = 1,
    cumulative.edgelist = TRUE,
    truncate.el.cuml    = 0,
    .tracker.list       = calibration_trackers,
    verbose             = FALSE
  )

  # Proposal to scenario -------------------------------------------------------
  scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
  param_sc <- EpiModel::use_scenario(param, scenario)

  # Simulation and processing --------------------------------------------------
  sim <- netsim(est, param_sc, init, control)

  as_tibble(sim) %>%
    mutate_calibration_targets() %>%
    filter(time >= max(time) - 52) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))
}

calibration2_fun <- function(proposal) {
  # Libraries ------------------------------------------------------------------
  library("EpiModelHIV")
  library("dplyr")

  # Settings -------------------------------------------------------------------
  source("./R/utils-0_project_settings.R")
  context <- "hpc"

  # Inputs ---------------------------------------------------------------------
  source("./R/utils-default_inputs.R", local = TRUE)
  est <- readRDS(path_to_restart)

  source("R/utils-targets.R")
  control <- control_msm(
    start               = restart_time,
    nsteps              = intervention_end,
    nsims               = 1,
    ncores              = 1,
    initialize.FUN      = reinit_msm,
    cumulative.edgelist = TRUE,
    truncate.el.cuml    = 0,
    .tracker.list       = calibration_trackers,
    verbose             = FALSE
  )

  # Proposal to scenario -------------------------------------------------------
  scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
  param_sc <- EpiModel::use_scenario(param, scenario)

  # Simulation and processing --------------------------------------------------
  sim <- netsim(est, param_sc, init, control)

  as_tibble(sim) %>%
    mutate_calibration_targets() %>%
    filter(time >= max(time) - 52) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))
}
