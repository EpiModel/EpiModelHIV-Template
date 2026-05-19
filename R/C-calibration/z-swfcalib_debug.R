pkgload::load_all("../swfcalib/")
source("R/shared_variables.R", local = TRUE)
calib_object <- readRDS(fs::path(swfcalib_dir, "calib_object.rds"))

  calib_object <- load_calib_object(calib_object)

  calib_object <- process_sim_results(calib_object)
  results <- load_results(calib_object)
  update_assessments(calib_object, results)

  calib_object <- update_calibration_state(calib_object, results)

  if (is_calibration_complete(calib_object)) {
    # When the calibration is done, skip the next step
    next_step <- slurmworkflow::get_current_workflow_step() + 2
    slurmworkflow::change_next_workflow_step(next_step)
    message("Calibration complete")
  } else {
    proposals <- make_proposals(calib_object, results)
    save_proposals(calib_object, proposals)
  }
  save_calib_object(calib_object)

make_proposals <- function(calib_object, results) {
  current_jobs <- get_current_jobs(calib_object, not_done_only = TRUE)
  if (get_current_iteration(calib_object) == 1) {
    proposals <- lapply(current_jobs, function(job) job$initial_proposals)
  } else {
    proposals <- lapply(
      current_jobs,
      function(co, job, res) job$make_next_proposals(co, job, res),
      res = results,
      co = calib_object
    )
  }
  proposals <- merge_proposals(proposals)
  proposals <- fill_proposals(proposals, calib_object)
  proposals[[".proposal_index"]] <- seq_len(nrow(proposals))
  proposals[[".wave"]] <- get_current_wave(calib_object)
  proposals[[".iteration"]] <- get_current_iteration(calib_object)
  dplyr::select(
    proposals,
    dplyr::everything(), ".proposal_index", ".wave", ".iteration"
  )
}

merge_proposals <- function(proposals) {
  max_rows <- max(vapply(proposals, nrow, numeric(1)))
  proposals <- lapply(
    proposals,
    function(d) {
      missing_rows <- max_rows - nrow(d)
      if (missing_rows > 0) {
        d <- dplyr::bind_rows(
          d,
          dplyr::slice_sample(d, n = missing_rows, replace = TRUE)
        )
      }
      d
    }
  )
  dplyr::bind_cols(proposals)
}
