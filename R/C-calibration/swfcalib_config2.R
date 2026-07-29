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

context <- "hpc"
source("R/C-calibration/z-context.R", local = TRUE)
library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)

source("./R/z-test.R")

n_sims <- 8
ors_calib <- seq(0.7, 1.3, length.out = n_sims)

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
targets <- c(targets, num = 100e3)

params_df <- params_df |>
  select(value, param) |>
  mutate(value = as.numeric(value)) |>
  pivot_wider(names_from = param)

# `p` percent of the pop have event in `i` steps
i2r_p <- function(i, p) 1 - (1 - p)^(1 / i)

priors <- list(
  # 50% of elig start prep in 3 months -> 4 years
  prep.start.rate = i2r_p(c(0.25, 4) * year_steps, 0.5),
  # 50% of HIV_dx neg test within 2 years -> 12 years
  hiv.test.rate = i2r_p(c(10, 30) * year_steps, 0.5),
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

waves_specs <- list(
  wave1 = list(
    job1 = list(
      targets = "cc.prep.B",
      init_ranges = list(prep.start.rate_1 = priors$prep.start.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    ),
    job2 = list(
      targets = "cc.prep.H",
      init_ranges = list(prep.start.rate_2 = priors$prep.start.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    ),
    job3 = list(
      targets = "cc.prep.W",
      init_ranges = list(prep.start.rate_3 = priors$prep.start.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    )
  ),
  wave2 = list(
    job1 = list(
      targets = "cc.dx.B",
      init_ranges = list(hiv.test.rate_1 = priors$hiv.test.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    ),
    job2 = list(
      targets = "cc.dx.H",
      init_ranges = list(hiv.test.rate_2 = priors$hiv.test.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    ),
    job3 = list(
      targets = "cc.dx.W",
      init_ranges = list(hiv.test.rate_3 = priors$hiv.test.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    )
  ),
  wave3 = list(
    job1 = list(
      targets = paste0("cc.vsupp.", c("B", "H", "W")),
      init_ranges = list(
        tx.halt.rate_1 = priors$tx.halt.rate,
        tx.halt.rate_2 = priors$tx.halt.rate,
        tx.halt.rate_3 = priors$tx.halt.rate
      ),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 3)
    )
  ),
  wave4 = list(
    job1 = list(
      targets = "ir100.gono",
      init_ranges = list(gono.uret.prob = priors$gono.uret.prob),
      proposal_fun = make_proposer_se_range(n_sims, retain_prop = 0.3),
      result_fun = swfcalib::determ_end_thresh(
        thresholds = 1,
        n_enough = 100
      )
    ),
    job2 = list(
      targets = "ir100.chla",
      init_ranges = list(chla.uret.prob = priors$chla.uret.prob),
      proposal_fun = make_proposer_se_range(n_sims, retain_prop = 0.3),
      result_fun = determ_end_thresh(
        thresholds = 1,
        n_enough = 100
      )
    ),
    job3 = list(
      targets = "ir100.syph",
      init_ranges = list(syph.prob = priors$syph.prob),
      proposal_fun = make_proposer_se_range(n_sims, retain_prop = 0.3),
      result_fun = determ_end_thresh(
        thresholds = 0.2,
        n_enough = 100
      )
    )
  ),
  wave5 = list(
    job1 = list(
      targets = paste0("i.prev.dx.", c("B", "H", "W")),
      init_ranges = list(
        hiv.trans.scale_1 = priors$hiv.trans.scale_1,
        hiv.trans.scale_2 = priors$hiv.trans.scale_2,
        hiv.trans.scale_3 = priors$hiv.trans.scale_3
      ),
      proposal_fun = make_proposer_se_range(n_sims, retain_prop = 0.3),
      result_fun = determ_end_thresh(
        thresholds = c(0.02, 0.02, 0.01),
        n_enough = 100
      )
    )
  ),
  wave6 = list(
    job0 = list(
      targets = "disease.mr100",
      init_ranges = list(
        aids.off.tx.mort.rate = priors$aids.off.tx.mort.rate
      ),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(0.001, poly_n = 5)
    )
  ),
  wave7 = list(
    job0 = list(
      targets = "num",
      init_ranges = list(a.rate = priors$a.rate),
      proposal_fun = make_shrink_proposer(n_sims, shrink = 2),
      result_fun = determ_poly_end(10, poly_n = 3)
    )
  )
)

calib_object <- make_calib_object(
  simulator = model_fn,
  root_directory = swfcalib_dir,
  max_iteration = 100,
  n_sims = n_sims,
  default_proposal = params_df,
  target_list = targets,
  waves_specs[c(8:10)]
)
calib_object

# Uncomment to run a single wave for testing
# calib_object$waves <- calib_object$waves[-c(1, 2, 3)]
