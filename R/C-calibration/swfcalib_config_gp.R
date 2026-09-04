## swfcalib Configuration 1 (pre-prep)
##
## Set up the configuration for the first calibration. This takes place before
## the restart point
##
## This script should not be run directly. But `sourced` from the swfcalib
## workflow
library(swfcalib)
library(dplyr)
library(tidyr)

n_sims <- 64

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)


source("./R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

params_df <- params_df |>
  select(value, param) |>
  mutate(value = as.numeric(value)) |>
  pivot_wider(names_from = param)


calib_object <- list(
  config = list(
    simulator = model_fn,
    root_directory = swfcalib_dir,
    max_iteration = 10,
    n_sims = n_sims,
    default_proposal = select(
      params_df,
      gono.uret.prob,
      chla.uret.prob,
      syph.prob
    )
  ),
  waves = list(
    wave4 = list(
      job1 = list(
        targets = "ir100.gono",
        targets_val = targets["ir100.gono"],
        params = c("gono.uret.prob"), # target:
        initial_proposals = tibble(
          gono.uret.prob = sample(rep(seq(0.1, 0.3, length.out = 16), 4))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end(
          tolerance = 0.5,
          extended_range = c(0.05, 0.5)
        )
      ),
      job2 = list(
        targets = "ir100.chla",
        targets_val = targets["ir100.chla"],
        params = c("chla.uret.prob"), # target:
        initial_proposals = tibble(
          chla.uret.prob = sample(rep(seq(0.1, 0.3, length.out = 16), 4))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end(
          tolerance = 0.5,
          extended_range = c(0.05, 0.5)
        )
      ),
      job3 = list(
        targets = "ir100.syph",
        targets_val = targets["ir100.syph"],
        params = c("syph.prob"), # target:
        initial_proposals = tibble(
          syph.prob = sample(rep(seq(0.1, 0.3, length.out = 16), 4))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end(
          tolerance = 0.25,
          extended_range = c(0.05, 0.5)
        )
      )
    )
  )
)
