source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

calib_object <- list(
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.prep.B",
        targets_val = 0.206,
        params = c("prep.start.prob_1"),
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.prep.H",
        targets_val = 0.237,
        params = c("prep.start.prob_2"),
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job3 = list(
        targets = "cc.prep.W",
        targets_val = 0.332,
        params = c("prep.start.prob_3"),
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
      )
    )
  ),
  config = list(
    simulator = calibration2_fun,
    default_proposal = dplyr::tibble(
      prep.start.prob_1 = 0.006,
      prep.start.prob_2 = 0.006,
      prep.start.prob_3 = 0.006
    ),
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims
  )
  # state = list() # managed internally
)
