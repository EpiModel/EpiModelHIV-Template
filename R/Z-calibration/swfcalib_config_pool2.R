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

n_sims <- 256
n_reps <- 4
restart <- TRUE

source("R/Z-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps, restart = restart)

source("./R/Z-calibration/het_gp_process.R", local = TRUE)

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
    max_iteration = 100,
    n_sims = n_sims,
    default_proposal = params_df |>
      select(starts_with(c(
        "prep.start.rate",
        "hiv.test.int",
        "tx.halt.rate",
        "hiv.trans.scale",
        "gono.uret.prob",
        "chla.uret.prob",
        "syph.prob",
        "aids.off.tx.mort.rate",
        "a.rate"
      )))
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = targets["cc.prep.B"],
        params = c("prep.start.rate_1"),
        initial_proposals = tibble(
          prep.start.rate_1 = sample(rep(
            seq(0.003, 0.005, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.001, 0.1))
      ),
      job2 = list(
        targets = "cc.prep.H",
        targets_val = targets["cc.prep.H"],
        params = c("prep.start.rate_2"),
        initial_proposals = tibble(
          prep.start.rate_2 = sample(rep(
            seq(0.003, 0.005, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.001, 0.1))
      ),
      job3 = list(
        targets = "cc.prep.W",
        targets_val = targets["cc.prep.W"],
        params = c("prep.start.rate_3"),
        initial_proposals = tibble(
          prep.start.rate_3 = sample(rep(
            seq(0.0045, 0.0065, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.001, 0.1))
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = targets["cc.dx.B"],
        params = c("hiv.test.int_1"),
        initial_proposals = tibble(
          hiv.test.int_1 = sample(rep(
            seq(550, 750, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(500, 1000))
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = targets["cc.dx.H"],
        params = c("hiv.test.int_2"),
        initial_proposals = tibble(
          hiv.test.int_2 = sample(rep(
            seq(730, 930, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(600, 1100))
      ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = targets["cc.dx.W"],
        params = c("hiv.test.int_3"), # target: 0.0069
        initial_proposals = tibble(
          hiv.test.int_3 = sample(rep(
            seq(625, 825, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(500, 1000))
      ),
      job4 = list(
        targets = "cc.vsupp.B",
        targets_val = targets["cc.vsupp.B"],
        params = "tx.halt.rate_1",
        initial_proposals = tibble(
          tx.halt.rate_1 = sample(rep(
            seq(0.0013, 0.0033, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0005, 0.01))
      ),
      job5 = list(
        targets = "cc.vsupp.H",
        targets_val = targets["cc.vsupp.H"],
        params = "tx.halt.rate_2",
        initial_proposals = tibble(
          tx.halt.rate_2 = sample(rep(
            seq(0.0011, 0.0031, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0005, 0.01))
      ),
      job6 = list(
        targets = "cc.vsupp.W",
        targets_val = targets["cc.vsupp.W"],
        params = "tx.halt.rate_3",
        initial_proposals = tibble(
          tx.halt.rate_3 = sample(rep(
            seq(0.0004, 0.0024, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.00025, 0.01))
      )
    ),
    wave3 = list(
      job1 = list(
        targets = "ir100.gono",
        targets_val = targets["ir100.gono"],
        params = c("gono.uret.prob"), # target:
        initial_proposals = tibble(
          gono.uret.prob = sample(rep(
            seq(0.18, 0.2, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.1, 0.2))
      ),
      job2 = list(
        targets = "ir100.chla",
        targets_val = targets["ir100.chla"],
        params = c("chla.uret.prob"), # target:
        initial_proposals = tibble(
          chla.uret.prob = sample(rep(
            seq(0.12, 0.14, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.1, 0.2))
      )
    )
  )
)
