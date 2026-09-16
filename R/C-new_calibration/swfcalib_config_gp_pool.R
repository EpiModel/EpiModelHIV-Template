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
n_reps <- 4

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)

source("./R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

scale_r <- list(c(2.5, 4.5), c(0.4, 0.8), c(0.2, 0.6))
lhs_unit <- lhs::maximinLHS(n_sims / n_reps, length(scale_r))
scale_params <- list()
for (i in 1:3)
  scale_params[[i]] <- lhs_unit[, i] * diff(scale_r[[i]]) + scale_r[[i]][1]
scale_params <- lapply(scale_params, rep, times = n_reps)

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
    default_proposal = tibble(
      prep.start.rate_1 = 0.0059217,
      prep.start.rate_2 = 0.004542306,
      prep.start.rate_3 = 0.006757837,
      hiv.test.rate_1 = 0.0006724602,
      hiv.test.rate_2 = 0.0009920079,
      hiv.test.rate_3 = 0.0006740063,
      tx.halt.rate_1 = 0.002236491,
      tx.halt.rate_2 = 0.002060115,
      tx.halt.rate_3 = 0.001382714,
      hiv.trans.scale_1 = 3.439541,
      hiv.trans.scale_2 = 0.6153605,
      hiv.trans.scale_3 = 0.4557934,
      gono.uret.prob = 0.2058703,
      chla.uret.prob = 0.1374851,
      syph.prob = 0.1315037,
      aids.off.tx.mort.rate = 0.00053713,
      a.rate = 0.00042235
    )
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = targets["cc.prep.B"],
        params = c("prep.start.rate_1"),
        initial_proposals = tibble(
          prep.start.rate_1 = sample(rep(
            seq(0.002, 0.01, length.out = n_sims / n_reps),
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
            seq(0.002, 0.01, length.out = n_sims / n_reps),
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
            seq(0.002, 0.01, length.out = n_sims / n_reps),
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
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = tibble(
          hiv.test.rate_1 = sample(rep(
            seq(0.0003, 0.001, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0001, 0.001))
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = targets["cc.dx.H"],
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = tibble(
          hiv.test.rate_2 = sample(rep(
            seq(0.0003, 0.001, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0001, 0.001))
      ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = targets["cc.dx.W"],
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = tibble(
          hiv.test.rate_3 = sample(rep(
            seq(0.0003, 0.001, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0001, 0.001))
      )
    ),
    wave3 = list(
      job1 = list(
        targets = "cc.vsupp.B",
        targets_val = targets["cc.vsupp.B"],
        params = "tx.halt.rate_1",
        initial_proposals = tibble(
          tx.halt.rate_1 = sample(rep(
            seq(0.001, 0.003, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0005, 0.01))
      ),
      job2 = list(
        targets = "cc.vsupp.H",
        targets_val = targets["cc.vsupp.H"],
        params = "tx.halt.rate_2",
        initial_proposals = tibble(
          tx.halt.rate_2 = sample(rep(
            seq(0.001, 0.003, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0005, 0.01))
      ),
      job3 = list(
        targets = "cc.vsupp.W",
        targets_val = targets["cc.vsupp.W"],
        params = "tx.halt.rate_3",
        initial_proposals = tibble(
          tx.halt.rate_3 = sample(rep(
            seq(0.0005, 0.003, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.00025, 0.01))
      )
    ),
    wave4 = list(
      job1 = list(
        targets = "ir100.gono",
        targets_val = targets["ir100.gono"],
        params = c("gono.uret.prob"), # target:
        initial_proposals = tibble(
          gono.uret.prob = sample(rep(
            seq(0.15, 0.25, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.05, 0.3))
      ),
      job2 = list(
        targets = "ir100.chla",
        targets_val = targets["ir100.chla"],
        params = c("chla.uret.prob"), # target:
        initial_proposals = tibble(
          chla.uret.prob = sample(rep(
            seq(0.1, 0.2, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.05, 0.3))
      ),
      job3 = list(
        targets = "ir100.syph",
        targets_val = targets["ir100.syph"],
        params = c("syph.prob"), # target:
        initial_proposals = tibble(
          syph.prob = sample(rep(
            seq(0.1, 0.2, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.05, 0.3))
      )
    ),
    wave5 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = targets[paste0("i.prev.dx.", c("B", "H", "W"))],
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = tibble(
          hiv.trans.scale_1 = scale_params[[1]],
          hiv.trans.scale_2 = scale_params[[2]],
          hiv.trans.scale_3 = scale_params[[3]]
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single3()
      )
    )
  )
)

# calib_object$waves <- calib_object$waves[-c(1, 2)]
