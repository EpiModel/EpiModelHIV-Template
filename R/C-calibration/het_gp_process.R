# if not target in range(realized outputs) -> use allowed range for scaling
# else, use realized input range
#
# fit hetGP
# stop rule
# get new proposals from hetgp
#
# if done, get uniroot of the case


# save centers in sideload using `list(centers = newp)`
#' @export
determ_gp_end <- function(tolerance, extended_range) {
  force(tolerance)
  force(extended_range)
  function(calib_object, job, results) {
    source("./R/C-calibration/z-gp_utils.R", local = TRUE)

    values <- results[[job$targets[1]]]
    params <- results[[job$params[1]]]
    target <- job$targets_val[1]

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    # Check that the value we want is in the output range - monotonic assumption
    if (target > min(values) && target < max(values)) {
      params_range <- range(params)
      check_end <- TRUE
    } else { # if not, use extended_range and let GP do it's magic
      params_range <- extended_range
      check_end <- FALSE
    }

    s_p <- mscale(params, params_range)

    mod <- hetGP::mleHetGP(s_p, values, covtype = "Matern5_2", eps = 1e-6)

    if (check_end) {
      grid01 <- seq(0, 1, length.out = 500)
      ci <- contour_ci(mod, thres = target, grid01)
      sub <- grid01[grid01 >= ci[1] & grid01 <= ci[2]]
      if (length(sub) < 2) sub <- ci[1:2]          # CI narrower than grid step
      y_span  <- predict(mod, matrix(sub, ncol = 1))$mean
      y_width <- diff(range(y_span))
      fcross <- ci["frac_crossing"]
      if (y_width < tolerance && fcross > 0.95) { # converged
        f_mean <- function(x) predict(mod, matrix(x, ncol = 1))$mean - target
        # search over the scaled domain;
        # assumes a single crossing (fine for monotone)
        root <- uniroot(f_mean, interval = c(0, 1))
        par_star <- munscale(root$root, params_range)
        result <- as.list(par_star)
        names(result) <- job$params
        return(dplyr::as_tibble(result))
      }
    }

    n_sims <- calib_object$config$n_sims
    s_new_p <- get_new_gp_prop(mod, n_sims)
    new_p <- munscale(s_new_p, params_range)

    proposals <- list(new_p)
    names(proposals) <- job$params[1]
    proposals <- dplyr::as_tibble(proposals)
    swfcalib::save_sideload(calib_object, job, list(proposals = proposals))

    return(NULL)
  }
}

proposer_load_sideload <- function(calib_object, job, results) {
  swfcalib::load_sideload(calib_object, job)$proposals
}
