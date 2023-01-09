model_fun <- function(proposal) {
  # Libraries ------------------------------------------------------------------
  library("EpiModelHIV")
  library("dplyr")

  # Settings -------------------------------------------------------------------
  source("./R/utils-0_project_settings.R")
  context <- "hpc"

  # Inputs ---------------------------------------------------------------------
  source("./R/utils-default_inputs.R")
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
  scenario_df <- proposal

  scenario_df[["rgc.prob"]] <-
    plogis(qlogis(scenario_df[["ugc.prob"]]) + log(1.25))
  scenario_df[["rct.prob"]] <-
    plogis(qlogis(scenario_df[["uct.prob"]]) + log(1.25))

  scenario_df[[".scenario.id"]] <- scenario_df[[".proposal_index"]]
  scenario_df[[".at"]] <- 1
  scenario_df[[".proposal_index"]] <- NULL
  scenario_df[[".wave"]] <- NULL
  scenario_df[[".iteration"]] <- NULL
  scenario <- EpiModel::create_scenario_list(scenario_df)[[1]]

  param_sc <- EpiModel::use_scenario(param, scenario)

  # Simulation and processing --------------------------------------------------
  sim <- netsim(est, param_sc, init, control)

  as_tibble(sim) %>%
    mutate_calibration_targets() %>%
    filter(time >= max(time) - 52) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across( everything(), ~ mean(.x, na.rm = TRUE)))
}
