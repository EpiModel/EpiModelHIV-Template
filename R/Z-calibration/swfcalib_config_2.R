## swfcalib Configuration 2 (post restart)
##
## Set up the configuration for the second calibration. This takes place after
## the restart point and will calibrate PrEP.
##
## This script should not be run directly. But `sourced` from the swfcalib
## workflow

source("R/Z-calibration/auto_cal_sim.R")
model_fn <- make_model_fn(restart = TRUE, calib_steps = year_steps)

n_sims <- 512

calib_object <- list(
  # state = list() # managed internally
  config = list(
    simulator = model_fn,
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims,
    default_proposal = dplyr::tibble(
      prep.start.prob_1 = 0.005,
      prep.start.prob_2 = 0.005,
      prep.start.prob_3 = 0.005,
      # remove after
      ugc.prob = 0.25,
      uct.prob = 0.17
    )
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = 0.199,
        params = c("prep.start.prob_1"),
        initial_proposals = dplyr::tibble(
          prep.start.prob_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.prep.H",
        targets_val = 0.229,
        params = c("prep.start.prob_2"),
        initial_proposals = dplyr::tibble(
          prep.start.prob_2 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.prep.W",
        targets_val = 0.321,
        params = c("prep.start.prob_3"),
        initial_proposals = dplyr::tibble(
          prep.start.prob_3 = seq(0.005, 0.02, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "ir100.gc",
        targets_val = 12.81,
        params = c("ugc.prob"), # target:
        initial_proposals = dplyr::tibble(
          ugc.prob = seq(0.2, 0.3, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      ),
      job2 = list(
        targets = "ir100.ct",
        targets_val = 14.59,
        params = c("uct.prob"), # target:
        initial_proposals = dplyr::tibble(
          uct.prob = seq(0.15, 0.25, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      )
    )
  )
)

