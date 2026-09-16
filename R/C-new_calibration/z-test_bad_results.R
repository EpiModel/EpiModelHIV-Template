# TODO: verify that I have results for ALL waves and iterations
# TODO: considering monotonous assumption, eval how deter gp fails and how to
# auto fix => goal: run "bad_calib" once and get ballparck at the end even with
# bad config

library(dplyr)
results_raw <- readRDS("./bad_results.rds")
source("./R/C-calibration/swfcalib_config_gp_bad.R")

wave_num <- 3
job_num <- 3
job <- calib_object$waves[[wave_num]][[job_num]]

results <- filter(
  results_raw,
  .wave == wave_num - 2,
  .iteration == 1
)
extended_range <- c(0.0005, 0.01)

results <- results[ results[[job$targets]] > job$targets_val, ]

determ_gp_end_single <- function(extended_range) {
  force(extended_range)
  function(calib_object, job, results) {
    library(hetGP)
    library(MASS)
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
    } else { # if not extend search on the relevant side
      ascending <- cor(values, params) > 0
      too_high <- min(values) >= target
      if (ascending == too_high) {
        new_r <- c(min(extended_range), min(params))
      } else {
        new_r <- c(max(params), max(extended_range))
      }
      n_unique <- length(unique(params))
      n_rep <- length(params) / n_unique
      new_p <- sample(
        rep(seq(new_r[1], new_r[2], length.out = n_unique), n_rep)
      )
      proposals <- list(new_p)
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

# TODO: make an "extend_range" function
#   - can I make it work for the 3 at once?
