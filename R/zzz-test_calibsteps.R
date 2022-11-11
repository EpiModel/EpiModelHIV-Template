pkgload::load_all("../../swfcalib")
library(swfcalib)
source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

calib_object <- readRDS("./data/calib/calib_object.rds")

calibrated_scenario <- calib_object$state$default_proposal
calibrated_scenario[[".at"]] <- 1
calibrated_scenario[[".scenario.id"]] <- "calibrated"

# calibration_step1(calib_object, n_cores = 1)
n_cores <- 1

oplan <- future::plan("multicore", workers = n_cores)
on.exit(future::plan(oplan), add = TRUE)

calib_object <- load_calib_object(calib_object)

calib_object <- process_sim_results(calib_object)
results <- load_results(calib_object)
calib_object <- update_calibration_state(calib_object, results)

job <- get_current_jobs(calib_object)[[1]]
res <- results
co <- calib_object
job$get_result(co, job, res)

if (is_calibration_complete(calib_object)) {
  wrap_up_calibration(calib_object)
} else {
  proposals <- make_proposals(calib_object, results)
  save_proposals(calib_object, proposals)
  save_calib_object(calib_object)
}

print_log(calib_object)

calibration_step2(calib_object, n_cores = 1)
calibration_step3(calib_object, n_cores = 1)


