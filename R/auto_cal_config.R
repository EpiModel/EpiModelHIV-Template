source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

calib_object <- list(
  waves = list(
    wave1 = list(
      job0 = list(
        targets = "disease.mr100",
        targets_val = 0.273,
        params = c("aids.off.tx.mort.rate"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          aids.off.tx.mort.rate = seq(0.0001, 0.001, length.out = n_sims),
        ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job1 = list(
        targets = "cc.dx.B",
        targets_val = 0.847,
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
          ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = 0.818,
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          hiv.test.rate_2 = seq(0.001, 0.01, length.out = n_sims),
          ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
        ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = 0.873,
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_3 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
        ),
      job4 = list(
        targets = "ir100.gc",
        targets_val = 12.81,
        params = c("ugc.prob", "rgc.prob"), # target:
        initial_proposals = dplyr::tibble(
          ugc.prob = seq(0.1, 0.8, length.out = n_sims),
          rgc.prob = plogis(qlogis(ugc.prob) + log(1.25))
        ),
        make_next_proposals = make_sti_range_proposer(n_sims),
        get_result = determ_trans_end(
          retain_prop = 0.3,
          thresholds = 1.5,
          n_enough = 100
        )
      ),
      job5 = list(
        targets = "ir100.ct",
        targets_val = 14.59,
        params = c("uct.prob", "rct.prob"), # target:
        initial_proposals = dplyr::tibble(
          uct.prob = seq(0.1, 0.8, length.out = n_sims),
          rct.prob = plogis(qlogis(uct.prob) + log(1.25))
        ),
        make_next_proposals = make_sti_range_proposer(n_sims),
        get_result = determ_trans_end(
          retain_prop = 0.3,
          thresholds = 1.5,
          n_enough = 100
        )
      ),
      job6 = list(
        targets = paste0("cc.linked1m.", c("B", "H", "W")),
        targets_val = c(0.829, 0.898, 0.890),
        params = paste0("tx.init.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = sample(seq(0.1, 0.5, length.out = n_sims)),
          tx.init.rate_2 = sample(tx.init.rate_1),
          tx.init.rate_3 = sample(tx.init.rate_1),
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001, poly_n = 3)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = paste0("cc.vsupp.", c("B", "H", "W")),
        targets_val = c(0.605, 0.620, 0.710),
        params = paste0("tx.halt.partial.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_1 = sample(seq(1e-3, 0.01, length.out = n_sims)),
          tx.halt.partial.rate_2 = sample(tx.halt.partial.rate_1),
          tx.halt.partial.rate_3 = sample(tx.halt.partial.rate_1)
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001, poly_n = 3)
      )
    ),
    wave3 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = c(0.33, 0.127, 0.084),
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = dplyr::tibble(
          hiv.trans.scale_1 = sample(seq(1, 6, length.out = n_sims)),
          hiv.trans.scale_2 = sample(seq(0.1, 1, length.out = n_sims)),
          hiv.trans.scale_3 = sample(seq(0.1, 1, length.out = n_sims))
        ),
        make_next_proposals = make_range_proposer(n_sims),
        get_result = determ_trans_end(
          retain_prop = 0.3,
          thresholds = rep(0.02, 3),
          n_enough = 100
        )
        # get_result = determ_lin_poly_end(c(0.005, 0.01, 0.01), poly_n = 1)
      )
    )
  ),
  config = list(
    simulator = model_fun,
    default_proposal = dplyr::tibble(
      hiv.test.rate_1 = 0.004123238,
      hiv.test.rate_2 = 0.003771226,
      hiv.test.rate_3 = 0.005956663,
      tx.init.rate_1 = 0.2981623,
      tx.init.rate_2 = 0.3680919,
      tx.init.rate_3 = 0.358254,
      ugc.prob = 0.1902003,
      rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
      uct.prob = 0.1714429,
      rct.prob = plogis(qlogis(uct.prob) + log(1.25)),
      tx.halt.partial.rate_1 = 0.004825257,
      tx.halt.partial.rate_2 = 0.00453566,
      tx.halt.partial.rate_3 = 0.003050059,
      hiv.trans.scale_1 = 2.470962,
      hiv.trans.scale_2 = 0.4247816,
      hiv.trans.scale_3 = 0.3342994,
      aids.off.tx.mort.rate = 0.0006
    ),
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims
  )
  # state = list() # managed internally
)
