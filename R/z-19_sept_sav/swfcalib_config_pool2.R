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

scale_r <- list(c(3.2, 3.6), c(0.48, 0.68), c(0.35, 0.55))
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
      prep.start.rate_1 = 0.00618729314160273,
      prep.start.rate_2 = 0.00440982245919091,
      prep.start.rate_3 = 0.00668163853137419,
      hiv.test.rate_1 = 0.000523435312703787,
      hiv.test.rate_2 = 0.00122948591033788,
      hiv.test.rate_3 = 0.000883788768393017,
      tx.halt.rate_1 = 0.00222545574993096,
      tx.halt.rate_2 = 0.00216070303585813,
      tx.halt.rate_3 = 0.00140203542678043,
      hiv.trans.scale_1 = 3.36365770068591,
      hiv.trans.scale_2 = 0.580800452808812,
      hiv.trans.scale_3 = 0.460377549851062,
      gono.uret.prob = 0.212740366728341,
      chla.uret.prob = 0.138208651824971,
      syph.prob = 0.135183517076581,
      aids.off.tx.mort.rate = 0.000560183753567694,
      a.rate = 0.000421105670303844
    )
  ),
  waves = list(
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
      ),
      job3 = list(
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
        get_result = determ_gp_end_single(extended_range = c(0.00038, 0.00046))
      )
    )
  )
)
