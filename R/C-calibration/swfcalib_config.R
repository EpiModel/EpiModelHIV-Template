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

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)

source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- project_calibration_targets()

# Only the numeric parameters are swept, but coercing the whole table would
# silently NA the character and logical ones (prep.lai.efficacy.model,
# prep.reinit.enable and friends). Keep those out of the wide frame rather than
# turning them into NA.
params_df <- params_df |>
  filter(is.na(type) | type == "numeric") |>
  select(value, param) |>
  mutate(value = as.numeric(value)) |>
  pivot_wider(names_from = param)

# `p` percent of the pop have event in `i` steps
i2r_p <- function(i, p) 1 - (1 - p)^(1 / i)

priors <- list(
  # 50% of elig start prep in 3 months -> 4 years
  prep.start.rate = i2r_p(c(0.25, 4) * year_steps, 0.5),
  # Mean waiting time to an HIV test, in timesteps: roughly 8 to 38 years.
  # This is hiv.test.int, not a rate, so it is not built with i2r_p().
  hiv.test.int = c(400, 2000),
  # 50% of ART user stop test within 2 years -> 8 years
  tx.halt.rate = i2r_p(c(5, 15) * year_steps, 0.5),
  # HIV transmission scaler: B needs to be high, H & W needs to be low
  hiv.trans.scale_1 = c(1.5, 5),
  hiv.trans.scale_2 = c(0.2, 0.9),
  hiv.trans.scale_3 = c(0.2, 0.9),
  # Priors for STI transmission risk per unprotected acts
  gono.uret.prob = c(0.17, 0.23),
  chla.uret.prob = c(0.17, 0.23),
  syph.prob = c(0.10, 0.13),
  # Median to death in AIDS stage: 15 years -> 40 years
  aids.off.tx.mort.rate = i2r_p(c(15, 40) * year_steps, 0.5),
  # Arrival per 1000 nodes in the model per week: 0.2 -> 0.6
  a.rate = c(0.0002, 0.0006)
)

priors <- lapply(priors, \(x) seq(x[1], x[2], length.out = n_sims))

calib_object <- list(
  config = list(
    simulator = model_fn,
    root_directory = swfcalib_dir,
    max_iteration = 100,
    n_sims = n_sims,
    default_proposal = select(
      params_df,
      prep.start.rate_1, prep.start.rate_2, prep.start.rate_3,
      hiv.test.int_1, hiv.test.int_2, hiv.test.int_3,
      tx.halt.rate_1, tx.halt.rate_2, tx.halt.rate_3,
      hiv.trans.scale_1, hiv.trans.scale_2, hiv.trans.scale_3,
      gono.uret.prob, chla.uret.prob, syph.prob,
      aids.off.tx.mort.rate,
      a.rate
    )
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = targets["cc.prep.B"],
        params = c("prep.start.rate_1"),
        initial_proposals = tibble(prep.start.rate_1 = priors$prep.start.rate),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.prep.H",
        targets_val = targets["cc.prep.H"],
        params = c("prep.start.rate_2"),
        initial_proposals = tibble(prep.start.rate_2 = priors$prep.start.rate),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.prep.W",
        targets_val = targets["cc.prep.W"],
        params = c("prep.start.rate_3"),
        initial_proposals = tibble(prep.start.rate_3 = priors$prep.start.rate),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = targets["cc.dx.B"],
        params = c("hiv.test.int_1"), # target: 0.00385
        initial_proposals = tibble(hiv.test.int_1 = priors$hiv.test.int),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = targets["cc.dx.H"],
        params = c("hiv.test.int_2"), # target: 0.0038
        initial_proposals = tibble(hiv.test.int_2 = priors$hiv.test.int),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = targets["cc.dx.W"],
        params = c("hiv.test.int_3"), # target: 0.0069
        initial_proposals = tibble(hiv.test.int_3 = priors$hiv.test.int),
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
          tx.halt.rate_1 = priors$tx.halt.rate,
          tx.halt.rate_2 = priors$tx.halt.rate,
          tx.halt.rate_3 = priors$tx.halt.rate
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
        initial_proposals = tibble(gono.uret.prob = priors$gono.uret.prob),
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
        initial_proposals = tibble(chla.uret.prob = priors$chla.uret.prob),
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
        initial_proposals = tibble(syph.prob = priors$syph.prob),
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
          hiv.trans.scale_1 = priors$hiv.trans.scale_1,
          hiv.trans.scale_2 = priors$hiv.trans.scale_2,
          hiv.trans.scale_3 = priors$hiv.trans.scale_3
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
          aids.off.tx.mort.rate = priors$aids.off.tx.mort.rate
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
        initial_proposals = tibble(a.rate = priors$a.rate),
        make_next_proposals = make_shrink_proposer(n_sims, shrink = 2),
        get_result = determ_poly_end(10, poly_n = 3)
      )
    )
  )
)

# Uncomment to run a single wave for testing
# calib_object$waves <- calib_object$waves[-c(1, 2, 3)]
