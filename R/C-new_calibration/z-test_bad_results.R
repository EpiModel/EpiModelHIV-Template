# TODO: verify that I have results for ALL waves and iterations
# TODO: considering monotonous assumption, eval how deter gp fails and how to
# auto fix => goal: run "bad_calib" once and get ballparck at the end even with
# bad config

library(dplyr)
library(EpiModelHIV)
hpc_context <- TRUE
source("./R/C-calibration/z-context.R")
source("./R/shared_variables.R")
source("./R/C-calibration/swfcalib_config_gp_bad.R")

results_raw <- readRDS("./bad_results.rds")

wave_num <- 3
job_num <- 3
job <- calib_object$waves[[wave_num]][[job_num]]

results <- filter(
  results_raw,
  .wave == wave_num - 2,
  .iteration == 1
)
extended_range <- c(0.0001, 0.01)

determ_gp_end_single <- function(extended_range) {
  force(extended_range)
  function(calib_object, job, results) {
    library(hetGP)
    library(MASS)
    source("./R/C-calibration/z-gp_utils.R", local = TRUE)

    values <- results[[job$targets[1]]]
    params <- results[[job$params[1]]]
    target <- job$targets_val[1]
    target <- 0.9

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    # Check if target is within reach, otherwise extend range
    # TODO: fail if range have been extended already
    new_proposal <- extend_param_range1(params, values, target, extended_range)
    if (!is.null(new_proposal)) {
      proposals <- list(new_proposal)
      names(proposals) <- job$params[1]
      proposals <- dplyr::as_tibble(proposals)
      swfcalib::save_sideload(calib_object, job, list(proposals = proposals))
      return(NULL)
    }

    s_p <- mscale(params, params_range)
    mod <- hetGP::mleHetGP(s_p, values, covtype = "Matern5_2", eps = 1e-6)
    f_mean <- function(x) predict(mod, matrix(x, ncol = 1))$mean - target
    root <- uniroot(f_mean, interval = c(0, 1))
    par_star <- munscale(root$root, params_range)
    result <- as.list(par_star)
    names(result) <- job$params
    return(dplyr::as_tibble(result))
  }
}

# If monotony not satisfied: stop
extend_param_range1 <- function(params, values, target, extended_range) {
  if (target > min(values) && target < max(values)) {
    return(NULL)
  }

  too_high <- max(values) >= target
  ascending <- cor(values, params) > 0
  if (ascending == too_high) {
    new_r <- c(min(extended_range), min(params))
  } else {
    new_r <- c(max(params), max(extended_range))
  }
  n_unique <- length(unique(params))
  n_rep <- length(params) / n_unique
  sample(rep(seq(new_r[1], new_r[2], length.out = n_unique), n_rep))
}

TODO:
# If monotony not satisfied: stop
extend_param_rangeN <- function(params, values, targets, extended_ranges) {
  oks <- rep(FALSE, length(targets))
  for (i in seq_along(values)) {
    if (targets[[i]] > min(values[[i]]) && targets[[i]] < max(values[[i]])) {
      oks[i] <- TRUE
    }
  }
  if (all(oks)) return(NULL)

  ascending <- cor(params[[1]], values[[1]]) > 0
  for (v in values) {
    for(p in params) {
      if (cor(p, v) > 0 != ascending) {
        stop("This function assumes that ")
      }
    }
  }
  too_high <- max(values) >= targets
  if (ascending == too_high) {
    new_r <- c(min(extended_range), min(params))
  } else {
    new_r <- c(max(params), max(extended_range))
  }
  n_unique <- length(unique(params))
  n_rep <- length(params) / n_unique
  sample(rep(seq(new_r[1], new_r[2], length.out = n_unique), n_rep))
}
