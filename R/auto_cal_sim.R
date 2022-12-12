model_fun <- function(proposal) {
  source("R/00-project_settings.R")
  library(EpiModelHIV)

  epistats <- readRDS("data/intermediate/estimates/epistats.rds")
  netstats <- readRDS("data/intermediate/estimates/netstats.rds")
  est      <- readRDS("data/intermediate/estimates/netest.rds")

  param <- param.net(
    data.frame.params = readr::read_csv("data/input/params.csv"),
    netstats          = netstats,
    epistats          = epistats,
    prep.start        = prep_start,
    riskh.start       = prep_start - 53,
    .param.updater.list = list(
      # High PrEP intake for the first year; go back to normal to get to 15%
      list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
      list(at = prep_start + 52, param = list(prep.start.prob = function(x) x/2))
    )
  )

  init <- init_msm(
    prev.ugc = 0.1,
    prev.rct = 0.1,
    prev.rgc = 0.1,
    prev.uct = 0.1
  )

  # Controls
  source("R/utils-targets.R")
  control <- control_msm(
    nsteps              = calibration_end,
    nsims               = 1,
    ncores              = 1,
    cumulative.edgelist = TRUE,
    truncate.el.cuml    = 0,
    .checkpoint.dir     = paste0("temp/cp_calib/", proposal[[".proposal_index"]], "/"),
    .checkpoint.clear   = TRUE,
    .checkpoint.steps   = 15 * 52,
    .tracker.list       = calibration_trackers,
    verbose             = FALSE
  )

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

  sim <- netsim(est, param_sc, init, control)

  source("R/utils-targets.R")
  as_tibble(sim) %>%
    mutate_targets() %>%
    filter(time >= max(time) - 52) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    ))
}
