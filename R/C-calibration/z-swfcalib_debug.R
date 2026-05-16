pkgload::load_all("../swfcalib/")
source("R/shared_variables.R", local = TRUE)
calib_object <- readRDS(fs::path(swfcalib_dir, "calib_object.rds"))

  oplan <- future::plan("multicore", workers = n_cores)
  on.exit(future::plan(oplan), add = TRUE)

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

  print_log(calib_object)
