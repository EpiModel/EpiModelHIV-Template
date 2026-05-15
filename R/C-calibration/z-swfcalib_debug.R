pkgload::load_all("../swfcalib/")
source("R/shared_variables.R", local = TRUE)
calib_object <- readRDS(fs::path(swfcalib_dir, "calib_object.rds"))

calib_object <- swfcalib:::load_calib_object(calib_object)
calib_object <- swfcalib:::process_sim_results(calib_object)
results <- swfcalib:::load_results(calib_object)
swfcalib:::update_assessments(calib_object, results)

calib_object <- swfcalib:::update_calibration_state(calib_object, results)


  function(calib_object, job, results) {
    centers <- swfcalib::load_sideload(calib_object, job)$centers
    if (is.null(centers)) {
      stop("No centers were provided for shrinkage, abort!")
    }

    outs <- list()
    for (i in seq_along(job$params)) {
      tar_range <- range(
        results[[job$params[i]]][
          results[[".iteration"]] == max(results[[".iteration"]])
        ]
      )
      spread <- (tar_range[2] - tar_range[1]) / shrink / 2

      proposals <- seq(
        max(centers[i] - spread, tar_range[1]),
        min(centers[i] + spread, tar_range[2]),
        length.out = n_new
      )

      proposals <- sample(proposals)

      out <- list(proposals)
      names(out) <- job$params[i]
      outs[[i]] <- dplyr::as_tibble(out)
    }
    dplyr::bind_cols(outs)
  }
