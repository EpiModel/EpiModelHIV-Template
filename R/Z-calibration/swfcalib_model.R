## swfcalib Model Function
##
## Define helper functions to create the `model` function for an swfcalib
## process.
##
## This script should not be run directly. But `sourced` from the
## swfcalib_config scripts.

make_model_fn <- function(calib_steps) {
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

    est <- readRDS(path_to_est)
    control <- control_msm(
      nsteps              = calibration_end,
      .tracker.list       = EpiModelHIV::make_calibration_trackers(),
      verbose             = FALSE
    )

    # Proposal to scenario -------------------------------------------------------
    scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
    param_sc <- EpiModel::use_scenario(param, scenario)

    # Simulation and processing --------------------------------------------------
    sim <- netsim(est, param_sc, init, control)
    targets <- EpiModelHIV::get_calibration_targets()

    as_tibble(sim) |>
      mutate_calibration_targets() |>
      filter(time >= max(time) - calib_steps) |>
      select(c(sim, num, any_of(names(targets)))) |>
      group_by(sim) |>
      summarise(across(everything(), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
  }
}
