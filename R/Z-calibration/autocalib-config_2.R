source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/auto_cal_sim.R")
model_fn <- make_model_fn(restart = TRUE, calib_steps = year_steps)

n_sims <- 512

calib_object <- list(
  config = list(
    simulator = calibration2_fun,
    default_proposal = dplyr::tibble(
      prep.start.prob_1 = 0.006,
      prep.start.prob_2 = 0.006,
      prep.start.prob_3 = 0.006,
      # remove after
      ugc.prob = 0.19,
      uct.prob = 0.17
    ),
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims
  ),
  # state = list() # managed internally
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
          prep.start.prob_3 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "ir100.gc",
        targets_val = 12.81,
        params = c("ugc.prob", "rgc.prob"), # target:
        initial_proposals = dplyr::tibble(
          ugc.prob = seq(0.2, 0.3, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1.5,
          n_enough = 100
        )
      ),
      job2 = list(
        targets = "ir100.ct",
        targets_val = 14.59,
        params = c("uct.prob", "rct.prob"), # target:
        initial_proposals = dplyr::tibble(
          uct.prob = seq(0.15, 0.25, length.out = n_sims),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1.5,
          n_enough = 100
        )
      )
    )
  )
)

