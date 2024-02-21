## swfcalib Configuration 1 (pre-prep)
##
## Set up the configuration for the first calibration. This takes place before
## the restart point and before PrEP is started.
##
## This script should not be run directly. But `sourced` from the swfcalib
## workflow

source("R/Z-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(restart = FALSE, calib_steps = year_steps)

n_sims <- 512

calib_object <- list(
  # state = list() # managed internally
  config = list(
    simulator = model_fn,
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims,
    default_proposal = dplyr::tibble(
      aids.off.tx.mort.rate = 0.0006,
      hiv.test.rate_1 = 0.004,
      hiv.test.rate_2 = 0.004,
      hiv.test.rate_3 = 0.006,
      tx.init.rate_1 = 0.3,
      tx.init.rate_2 = 0.4,
      tx.init.rate_3 = 0.4,
      ugc.prob = 0.3,
      uct.prob = 0.2,
      tx.halt.partial.rate_1 = 0.005,
      tx.halt.partial.rate_2 = 0.005,
      tx.halt.partial.rate_3 = 0.003,
      hiv.trans.scale_1 = 2.5,
      hiv.trans.scale_2 = 0.4,
      hiv.trans.scale_3 = 0.3
    )
  ),
  waves = list(
    wave1 = list(
      job0 = list(
        targets = "disease.mr100",
        targets_val = 0.273,
        params = c("aids.off.tx.mort.rate"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          aids.off.tx.mort.rate = sample(seq(0.0002, 0.0007, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      ),
      job1 = list(
        targets = "cc.dx.B",
        targets_val = 0.847,
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = sample(seq(0.002, 0.006, length.out = n_sims)),
          ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = 0.818,
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          hiv.test.rate_2 = sample(seq(0.002, 0.006, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
        ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = 0.862,
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_3 = sample(seq(0.004, 0.008, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      ),
      job4 = list(
        targets = "ir100.gc",
        targets_val = 12.81,
        params = c("ugc.prob"), # target:
        initial_proposals = dplyr::tibble(
          ugc.prob = sample(seq(0.2, 0.3, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      ),
      job5 = list(
        targets = "ir100.ct",
        targets_val = 14.59,
        params = c("uct.prob"), # target:
        initial_proposals = dplyr::tibble(
          uct.prob = sample(seq(0.15, 0.25, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = 1,
          n_enough = 100
        )
      ),
      job6 = list(
        targets = paste0("cc.linked1m.", c("B", "H", "W")),
        targets_val = c(0.829, 0.898, 0.881),
        params = paste0("tx.init.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = sample(seq(0.1, 0.5, length.out = n_sims)),
          tx.init.rate_2 = sample(tx.init.rate_1),
          tx.init.rate_3 = sample(tx.init.rate_1),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 3)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = paste0("cc.vsupp.", c("B", "H", "W")),
        targets_val = c(0.602, 0.620, 0.712),
        params = paste0("tx.halt.partial.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_1 = sample(seq(0.002, 0.006, length.out = n_sims)),
          tx.halt.partial.rate_2 = sample(tx.halt.partial.rate_1),
          tx.halt.partial.rate_3 = sample(tx.halt.partial.rate_1)
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 3)
      )
    ),
    wave3 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = c(0.33, 0.127, 0.09),
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = dplyr::tibble(
          hiv.trans.scale_1 = sample(seq(1, 4, length.out = n_sims)),
          hiv.trans.scale_2 = sample(seq(0.2, 0.6, length.out = n_sims)),
          hiv.trans.scale_3 = sample(seq(0.2, 0.6, length.out = n_sims))
        ),
        make_next_proposals = swfcalib::make_proposer_se_range(n_sims, retain_prop = 0.3),
        get_result = swfcalib::determ_end_thresh(
          thresholds = c(0.02, 0.02, 0.01),
          n_enough = 100
        )
      )
    ),
    wave4 = list(
      job0 = list(
        targets = "disease.mr100",
        targets_val = 0.273,
        params = c("aids.off.tx.mort.rate"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          aids.off.tx.mort.rate = sample(seq(0.0002, 0.0007, length.out = n_sims)),
        ),
        make_next_proposals = swfcalib::make_shrink_proposer(n_sims, shrink = 2),
        get_result = swfcalib::determ_poly_end(0.001, poly_n = 5)
      )
    )
  )
)
