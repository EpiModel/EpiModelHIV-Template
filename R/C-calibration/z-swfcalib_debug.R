pkgload::load_all("../swfcalib/")
source("R/shared_variables.R", local = TRUE)
calib_object <- readRDS(fs::path(swfcalib_dir, "calib_object.rds"))

calib_object <- swfcalib:::load_calib_object(calib_object)
calib_object <- swfcalib:::process_sim_results(calib_object)
results <- swfcalib:::load_results(calib_object)
swfcalib:::update_assessments(calib_object, results)

calib_object <- swfcalib:::update_calibration_state(calib_object, results)


update_calibration_state <- function(calib_object, results) {
  # Do not check the results on the first iteration
  if (get_current_iteration(calib_object) > 0) {
    jobs_results <- get_jobs_results(calib_object, results)

get_jobs_results <- function(calib_object, results) {
  lapply(
    jobs <- get_current_jobs(calib_object)
    job = jobs[[1]]
    co = calib_object
    res = results
    function(co, job, res) job$get_result(co, job, res),
    res = results,
    co = calib_object
  )
}



    calib_object <- update_done_status(calib_object, jobs_results)
    calib_object <- update_default_proposal(calib_object, jobs_results)
  }
  calib_object <- update_wave_iteration(calib_object)
  calib_object
}

is_valid_iteration <- function(calib_object) {
  get_current_iteration(calib_object) <= get_max_iteration(calib_object)
}

is_calibration_complete <- function(calib_object) {
  is_last_wave(calib_object) && is_wave_done(calib_object)
}







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

print_log(calib_object)

  calib_object <- swfcalib:::load_calib_object(calib_object)
  proposals <- swfcalib:::load_proposals(calib_object)

  seq_sim <- swfcalib:::get_seq_sim(calib_object, batch_num, n_cores)

  future.apply::future_lapply(
    seq_sim,
    function(i, calib_object, proposals) {
      proposal <- swfcalib:::get_proposal_n(proposals, i)
      sim_result <- swfcalib:::run_simulation(calib_object, proposal)
      swfcalib:::save_sim_result(calib_object, sim_result, i, proposal)
    },
    calib_object = calib_object,
    proposals = proposals,
    future.seed = TRUE
  )

  # last batch set the workflow to go back one step
  if (batch_num == n_batches) {
    next_step <- slurmworkflow::get_current_workflow_step() - 1
    slurmworkflow::change_next_workflow_step(next_step)
  }
