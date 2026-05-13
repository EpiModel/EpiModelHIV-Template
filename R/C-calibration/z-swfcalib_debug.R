library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results <- readRDS(fs::path(swfcalib_dir, "waves/1/", "results.rds"))
proposals <- readRDS(fs::path(swfcalib_dir, "waves/1/", "proposals.rds"))
calib_object <- readRDS(fs::path(swfcalib_dir, "calib_object.rds"))

pkgload::load_all("../swfcalib/")

calib_object <- swfcalib:::load_calib_object(calib_object)
calib_object <- swfcalib:::process_sim_results(calib_object)
results <- swfcalib:::load_results(calib_object)
swfcalib:::update_assessments(calib_object, results)

  out <- swfcalib:::load_assessments(calib_object)
  if (nrow(results) == 0) {
    swfcalib:::save_assessments(calib_object, out)
    return(invisible(calib_object))
  }

  cur_wave <- paste0("wave", swfcalib:::get_current_wave(calib_object))

  assessments <- lapply(
    swfcalib:::get_current_jobs(calib_object),
    swfcalib:::make_job_assessment,
    calib_object = calib_object,
    results = results
  )

  out[[cur_wave]] <- merge_wave_assements(assessments, out[[cur_wave]])
  save_assessments(calib_object, out)
  invisible(calib_object)


results <- swfcalib::load_results(calib_object)
swfcalib::update_assessments(calib_object, results)

calib_object <- swfcalib::update_calibration_state(calib_object, results)

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
