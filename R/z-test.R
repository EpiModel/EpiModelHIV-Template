make_calib_object <- function(
  simulator,
  root_directory,
  max_iteration,
  n_sims,
  default_proposal,
  target_list,
  waves_specs
) {
  waves <- lapply(
    waves_specs,
    make_wave,
    target_list = target_list,
    n_sims = n_sims
  )
  # Check the name of the params actually useful for the current calibration
  params <- character(0)
  for (wave in waves) {
    for (job in wave) {
      params <- c(params, job$params)
    }
  }
  missing_proposals <- setdiff(params, names(default_proposal))
  if (length(missing_proposals) > 0) {
    stop(
      "The following parameters to be calibrated are not present in ",
      "`default_proposal`: \n      - `",
      paste0(missing_proposals, collapse = "`\n      - `"),
      "`"
    )
  }

  calib_object <- list(
    config = list(
      simulator = simulator,
      root_directory = root_directory,
      max_iteration = max_iteration,
      n_sims = n_sims,
      default_proposal = default_proposal[, params, drop = FALSE]
    ),
    waves = waves
  )

  class(calib_object) <- c("swfcalib_calib_object", class(calib_object))
  calib_object
}

make_wave <- function(jobs_specs, n_sims, target_list) {
  wave <- lapply(jobs_specs, \(j) {
    make_job(
      target_list,
      n_sims,
      j$targets,
      j$init_ranges,
      j$proposal_fun,
      j$result_fun
    )
  })
  class(wave) <- c("swfcalib_wave", class(wave))
  wave
}

make_job <- function(
  target_list,
  n_sims,
  targets,
  init_ranges,
  proposal_fun,
  result_fun
) {
  err_ranges <- vapply(init_ranges, \(x) x[1] == x[2], TRUE)
  if (any(err_ranges)) {
    stop(
      "The `init_ranges` values must be different. Errors for: \n      - `",
      paste0(names(init_ranges)[err_ranges], collapse = "`, "),
      "`"
    )
  }

  initial_proposals <- lapply(
    init_ranges,
    \(x) sample(seq(x[1], x[2], length.out = n_sims))
  )
  names(initial_proposals) <- names(init_ranges)
  initial_proposals <- as.data.frame(initial_proposals)

  job <- list(
    targets = targets,
    targets_val = target_list[targets],
    params = names(initial_proposals),
    initial_proposals = initial_proposals,
    make_next_proposals = proposal_fun,
    get_result = result_fun
  )

  class(job) <- c("swfcalib_job", class(job))
  job
}
