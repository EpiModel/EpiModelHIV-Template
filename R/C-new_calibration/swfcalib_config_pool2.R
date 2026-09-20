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
restart <- TRUE

source("R/C-new_calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps, restart)

source("./R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

scale_r <- list(c(3, 4), c(0.5, 0.7), c(0.3, 0.5))
lhs_unit <- lhs::maximinLHS(n_sims / n_reps, length(scale_r))
scale_params <- list()
for (i in 1:3) {
  scale_params[[i]] <- lhs_unit[, i] * diff(scale_r[[i]]) + scale_r[[i]][1]
}
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
      prep.start.rate_1 = 0.006196075,
      prep.start.rate_2 = 0.004415846,
      prep.start.rate_3 = 0.006695219,
      hiv.test.rate_1 = 0.0005183391,
      hiv.test.rate_2 = 0.001187404,
      hiv.test.rate_3 = 0.0009428464,
      tx.halt.rate_1 = 0.002216292,
      tx.halt.rate_2 = 0.002104127,
      tx.halt.rate_3 = 0.00140024,
      hiv.trans.scale_1 = 3.3957,
      hiv.trans.scale_2 = 0.6284651,
      hiv.trans.scale_3 = 0.461866,
      gono.uret.prob = 0.2134161,
      chla.uret.prob = 0.1382954,
      syph.prob = 0.1348612,
      aids.off.tx.mort.rate = 0.0005409678,
      a.rate = 0.0004222143
    )
  ),
  waves = list(
    wave3 = list(
      job1 = list(
        targets = "ir100.gono",
        targets_val = targets["ir100.gono"],
        params = c("gono.uret.prob"), # target:
        initial_proposals = tibble(
          gono.uret.prob = sample(rep(
            seq(0.18, 0.23, length.out = n_sims / n_reps),
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
            seq(0.12, 0.16, length.out = n_sims / n_reps),
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
    wave4 = list(
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
