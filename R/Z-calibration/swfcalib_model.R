## swfcalib Model Function
##
## Define helper functions to create the `model` function for an swfcalib
## process.
##
## This script should not be run directly. But `sourced` from the
## swfcalib_config scripts.

make_model_fn <- function(restart, calib_steps) {
  force(restart)
  force(calib_steps)

  function(proposal) {
    # Libraries ------------------------------------------------------------------
    library("EpiModelHIV")
    library("dplyr")

    # Settings -------------------------------------------------------------------
    source("R/shared_variables.R", local = TRUE)
    hpc_context <- TRUE
    source("R/Z-calibration/z-context.R", local = TRUE)

    # Inputs ---------------------------------------------------------------------
    source("R/netsim_settings.R", local = TRUE)

    if (restart) {
      est <- readRDS(path_to_restart)
      control <- control_msm(
        start               = restart_time,
        nsteps              = intervention_start,
        initialize.FUN      = reinit_msm,
        .tracker.list       = EpiModelHIV::make_calibration_trackers(),
        verbose             = FALSE
      )
    } else {
      est <- readRDS(path_to_est)
      control <- control_msm(
        nsteps              = calibration_end,
        .tracker.list       = EpiModelHIV::make_calibration_trackers(),
        verbose             = FALSE
      )
    }

    # Proposal to scenario -------------------------------------------------------
    scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
    param_sc <- EpiModel::use_scenario(param, scenario)

    param_sc$rgc.prob <- plogis(qlogis(param_sc$ugc.prob) + log(1.25))
    param_sc$rct.prob <- plogis(qlogis(param_sc$uct.prob) + log(1.25))

    # Simulation and processing --------------------------------------------------
    sim <- netsim(est, param_sc, init, control)
    targets <- EpiModelHIV::get_calibration_targets()

    as_tibble(sim) |>
      mutate_calibration_targets() |>
      filter(time >= max(time) - calib_steps) |>
      select(c(sim, any_of(names(targets)))) |>
      group_by(sim) |>
      summarise(across(everything(), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
  }
}
