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

n_sims <- 128
n_reps <- 4

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)

source("./R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

scale_r <- list(c(2.5, 4), c(0.2, 0.7), c(0.2, 0.7))
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
      prep.start.rate_1 = 0.005828601,
      prep.start.rate_2 = 0.004505324,
      prep.start.rate_3 = 0.006700008,
      hiv.test.rate_1 = 0.0006918843,
      hiv.test.rate_2 = 0.0009446952,
      hiv.test.rate_3 = 0.0005295467,
      tx.halt.rate_1 = 0.002220137,
      tx.halt.rate_2 = 0.00207386,
      tx.halt.rate_3 = 0.001382076,
      hiv.trans.scale_1 = 3.140432,
      hiv.trans.scale_2 = 0.5378885,
      hiv.trans.scale_3 = 0.4022414,
      gono.uret.prob = 0.2379301,
      chla.uret.prob = 0.1693996,
      syph.prob = 0.1419804,
      aids.off.tx.mort.rate = 0.0005657358,
      a.rate = 0.0004228719
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
            seq(0.004, 0.008, length.out = n_sims / n_reps),
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
            seq(0.0025, 0.075, length.out = n_sims / n_reps),
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
            seq(0.005, 0.01, length.out = n_sims / n_reps),
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
            seq(0.0002, 0.0012, length.out = n_sims / n_reps),
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
            seq(0.0005, 0.0015, length.out = n_sims / n_reps),
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
            seq(0.0002, 0.012, length.out = n_sims / n_reps),
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
            seq(0.0015, 0.003, length.out = n_sims / n_reps),
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
            seq(0.0015, 0.003, length.out = n_sims / n_reps),
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
            seq(0.001, 0.002, length.out = n_sims / n_reps),
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
            seq(0.12, 0.17, length.out = n_sims / n_reps),
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
            seq(0.12, 0.15, length.out = n_sims / n_reps),
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
    ),
    wave6 = list(
      job2 = list(
        targets = "disease.mr100",
        targets_val = targets["disease.mr100"],
        params = c("aids.off.tx.mort.rate"), # target: 0.00385
        initial_proposals = tibble(
          aids.off.tx.mort.rate = sample(rep(
            seq(0.0003, 0.0006, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0001, 0.001))
      ),
      job2 = list(
        targets = "num",
        targets_val = 100e3,
        params = c("a.rate"),
        initial_proposals = tibble(
          a.rate = sample(rep(
            seq(0.00025, 0.0005, length.out = n_sims / n_reps),
            n_reps
          ))
        ),
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_end_single(extended_range = c(0.0001, 0.001))
      )
    )
  )
)
