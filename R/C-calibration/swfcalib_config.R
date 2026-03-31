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
ors_calib <- seq(0.7, 1.3, length.out = n_sims)

source("R/Z-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)

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
    default_proposal = select(
      params_df,
      prep.start.rate_1, prep.start.rate_2, prep.start.rate_3,
      aids.off.tx.mort.rate,
      hiv.test.rate_1, hiv.test.rate_2, hiv.test.rate_3,
      gono.uret.prob, chla.uret.prob, syph.prob,
      tx.halt.rate_1, tx.halt.rate_2, tx.halt.rate_3,
      hiv.trans.scale_1, hiv.trans.scale_2, hiv.trans.scale_3,
      a.rate
    )
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = targets["cc.prep.B"],
        params = c("prep.start.rate_1"),
        initial_proposals = tibble(
          prep.start.rate_1 =
            params_df$prep.start.rate_1 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.prep.H",
        targets_val = targets["cc.prep.H"],
        params = c("prep.start.rate_2"),
        initial_proposals = tibble(
          prep.start.rate_2 =
            params_df$prep.start.rate_2 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.prep.W",
        targets_val = targets["cc.prep.W"],
        params = c("prep.start.rate_3"),
        initial_proposals = dplyr::tibble(
          prep.start.rate_3 =
            params_df$prep.start.rate_3 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = targets["cc.dx.B"],
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = tibble(
          hiv.test.rate_1 =
            params_df$hiv.test.rate_1 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = targets["cc.dx.H"],
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = tibble(
          hiv.test.rate_2 =
            params_df$hiv.test.rate_2 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = targets["cc.dx.W"],
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = tibble(
          hiv.test.rate_3 =
            params_df$hiv.test.rate_3 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave3 = list(
      job1 = list(
        targets = paste0("cc.vsupp.", c("B", "H", "W")),
        targets_val = targets[paste0("cc.vsupp.", c("B", "H", "W"))],
        params = paste0("tx.halt.rate_", 1:3),
        initial_proposals = tibble(
          tx.halt.rate_1 =
            params_df$tx.halt.rate_1 * ors_calib,
          tx.halt.rate_2 =
            params_df$tx.halt.rate_2 * ors_calib,
          tx.halt.rate_3 =
            params_df$tx.halt.rate_3 * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 3)
      )
    ),
    wave4 = list(
      job1 = list(
        targets = "ir100.gono",
        targets_val = targets["ir100.gono"],
        params = c("gono.uret.prob"), # target:
        initial_proposals = tibble(
          gono.uret.prob =
            params_df$gono.uret.prob * ors_calib
        ),
        make_next_proposals = make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      ),
      job2 = list(
        targets = "ir100.chla",
        targets_val = targets["ir100.chla"],
        params = c("chla.uret.prob"), # target:
        initial_proposals = dplyr::tibble(
          chla.uret.prob =
            params_df$chla.uret.prob * ors_calib
        ),
        make_next_proposals = make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      ),
      job3 = list(
        targets = "ir100.syph",
        targets_val = targets["ir100.syph"],
        params = c("syph.prob"), # target:
        initial_proposals = dplyr::tibble(
          syph.prob =
            params_df$syph.prob * ors_calib
        ),
        make_next_proposals = make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = determ_end_thresh(
          thresholds = 0.2,
          n_enough = 100
        )
      )
    ),
    wave5 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = targets[paste0("i.prev.dx.", c("B", "H", "W"))],
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = tibble(
          hiv.trans.scale_1 =
            params_df$hiv.trans.scale_1 * ors_calib,
          hiv.trans.scale_2 =
            params_df$hiv.trans.scale_2 * ors_calib,
          hiv.trans.scale_3 =
            params_df$hiv.trans.scale_3 * ors_calib
        ),
        make_next_proposals = make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = determ_end_thresh(
          thresholds = c(0.02, 0.02, 0.01),
          n_enough = 100
        )
      )
    ),
    wave6 = list(
      job0 = list(
        targets = "disease.mr100",
        targets_val = targets["disease.mr100"],
        params = c("aids.off.tx.mort.rate"), # target: 0.00385
        initial_proposals = tibble(
          aids.off.tx.mort.rate =
            params_df$aids.off.tx.mort.rate * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave7 = list(
      job0 = list(
        targets = "num",
        targets_val = 100e3,
        params = c("a.rate"),
        initial_proposals = tibble(
          a.rate =
            params_df$a.rate * ors_calib
        ),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(10, poly_n = 3)
      )
    )
  )
)

# # Limit the number of waves to run
calib_object$waves <- calib_object$waves[5]
