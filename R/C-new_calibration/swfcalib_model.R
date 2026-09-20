## swfcalib Model Function
##
## Define helper functions to create the `model` function for an swfcalib
## process.
##
## This script should not be run directly. But `sourced` from the
## swfcalib_config scripts.

make_model_fn <- function(calib_steps, restart = FALSE) {
  force(calib_steps)
  force(restart)
  function(proposal) {
    # Libraries - --------------------------------------------------------------
    library(EpiModelHIV)
    library(dplyr)

    # Settings -----------------------------------------------------------------
    hpc_context <- TRUE
    source("R/shared_variables.R", local = TRUE)
    source("R/C-new_calibration/z-context.R", local = TRUE)

    # Inputs -------------------------------------------------------------------
    source("R/netsim_settings.R", local = TRUE)

    if (restart) {
      orig <- readRDS(path_to_restart)
      control <- control_msm(
        nsteps = calibration_end,
        start = restart_time,
        randomize.restart = TRUE,
        initialize.FUN = initialize.net,
        verbose = FALSE
      )
    } else {
      orig <- readRDS(path_to_est)
      control <- control_msm(
        nsteps = calibration_end,
        verbose = FALSE
      )
    }

    # Proposal to scenario -----------------------------------------------------
    scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
    param_sc <- EpiModel::use_scenario(param, scenario)

    # Simulation and processing ------------------------------------------------
    sim <- netsim(orig, param_sc, init, control)
    targets <- EpiModelHIV::get_calibration_targets()

    as_tibble(sim) |>
      mutate_calibration_targets() |>
      filter(time >= max(time) - calib_steps) |>
      select(c(sim, num, any_of(names(targets)))) |>
      group_by(sim) |>
      summarise(
        across(
          everything(),
          \(x) mean(x, na.rm = TRUE)
        ),
        .groups = "drop"
      )
  }
}
