proposer_load_sideload <- function(calib_object, job, results) {
  swfcalib::load_sideload(calib_object, job)$proposals
}

determ_gp_end_single3 <- function() {
  function(calib_object, job, results) {
    library(hetGP)
    library(MASS)
    source("./R/Z-calibration/z-gp_utils.R", local = TRUE)

    par_names <- job$params
    par_raws <- results[par_names]
    par_ranges <- lapply(par_raws, range)
    tar_names <- job$targets
    tars <- job$targets_val

    X <- mapply(mscale, par_raws, par_ranges)

    mods <- lapply(tar_names, \(tar_name) {
      val <- results[[tar_name]]
      mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)
    })
    names(mods) <- tar_names

    resid <- function(u) {
      xm <- matrix(pmin(pmax(u, 0), 1), nrow = 1)
      sapply(seq_along(mods), function(k) predict(mods[[k]], xm)$mean - tars[k])
    }

    fit <- minpack.lm::nls.lm(
      par = rep(0.5, 3),
      fn = resid,
      lower = rep(0, 3),
      upper = rep(1, 3)
    )
    par_star <- setNames(mapply(munscale, fit$par, par_ranges), par_names)
    result <- as.list(par_star)
    names(result) <- job$params
    return(dplyr::as_tibble(result))
  }
}

determ_gp_end_single <- function(extended_range) {
  force(extended_range)
  function(calib_object, job, results) {
    library(hetGP)
    library(MASS)
    source("./R/Z-calibration/z-gp_utils.R", local = TRUE)

    values <- results[[job$targets[1]]]
    params <- results[[job$params[1]]]
    target <- job$targets_val[1]

    n_batch <- length(unique(params)) # design size, before dropping NAs

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    params_range <- range(params)
    s_p <- mscale(params, params_range)

    mod <- hetGP::mleHetGP(s_p, values, covtype = "Matern5_2", eps = 1e-6)

    f_mean <- function(x) predict(mod, matrix(x, ncol = 1))$mean - target
    # search the scaled domain; assumes a single crossing (fine for monotone)
    # if it fails, expand the search range
    root <- tryCatch(
      expr = uniroot(f_mean, interval = c(0, 1))$root,
      error = function(e) NA
    )
    if (!is.na(root)) { # root found
      proposals <- list(results[[job$params[1]]])
      names(proposals) <- job$params[1]
      proposals <- dplyr::as_tibble(proposals)
      swfcalib::save_sideload(calib_object, job, list(proposals = proposals))

      par_star <- munscale(root, params_range)
      result <- as.list(par_star)
      names(result) <- job$params
      return(dplyr::as_tibble(result))
    }

    n_sims <- calib_object$config$n_sims
    n_rep <- n_sims / n_batch
    new_range <- extended_range
    new_p <- seq(new_range[1], new_range[2], length.out = n_batch)
    new_p <- sample(rep(new_p, n_rep))

    proposals <- list(new_p)
    names(proposals) <- job$params[1]
    proposals <- dplyr::as_tibble(proposals)
    swfcalib::save_sideload(calib_object, job, list(proposals = proposals))

    return(NULL)
  }
}
