# Proposer:
#   function(calib_object, job, results) ->
#       tibble(param1, param2, ...): n_sims rows (ideally)
#
# End Checker:
#   function(calib_object, job, results) ->
#     if not done: NULL
#     else:        tibble(param1, param2, ...): 1 row (crash otherwise)
#
# checker runs first. They can comunicate with:
# `swfcalib::save_sideload(calib_object, job, some_data)` and
# `swfcalib::load_sideload(calib_object, job)`.
#     useful to prevent dual calculations (calc in check and reuse in proposer)

make_partition_proposer <- function(partitions, allowed_range = c(-Inf, Inf)) {
  if (partitions < 3)
    stop("`partitions` must be greater than or equal to 3")

  function(calib_object, job, results) {
    values <- results[[job$targets]]
    target <- job$targets_val

    calib_res <- dplyr::tibble(
      param = results[[job$params]],
      dist = values - target,
      loss = abs(dist)
    )

    calib_res <- dplyr::arrange(calib_res, dist)
    sign_switch <- which(calib_res$dist > 0)[1] #NA if none found
    if (is.na(sign_switch) || sign_switch == 1) {
      calib_res <- dplyr::arrange(calib_res, loss)
      borders <- c(
        calib_res$param[1],
        2 * calib_res$param[1] - calib_res$param[nrow(calib_res)]
      )
      borders <- vapply(
        borders,
        function(x) min(max(x, allowed_range[1]), allowed_range[2]),
        numeric(1)
      )
      proposals <- seq(borders[1], borders[2], length.out = partitions)
      out <- list(proposals[2:partitions])
    } else {
      calib_res <- calib_res[c(sign_switch - 1, sign_switch), ]
      borders <- calib_res[["param"]]
      proposals <- seq(borders[1], borders[2], length.out = partitions)
      out <- list(proposals[2:(partitions - 1)])
    }
    names(out) <- job$params
    dplyr::as_tibble(out)
  }
}

# ------------------------------------------------------------------------------
make_noisy_proposer <- function(n_new, n_best) {
  force(n_new)
  force(n_best)
  function(calib_object, job, results) {
    values <- results[[job$targets]]
    param <- results[[job$params]]
    target <- job$targets_val

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    param <- param[complete_rows]

    # warning, only work on unique values
    calib_res <- dplyr::tibble(
      param = results[[job$params]],
      dist = values - target,
      loss = abs(dist)
    )

    calib_res <- dplyr::arrange(calib_res, loss)
    new_range <- range(calib_res$param[seq_len(n_best)])

    proposals <- seq(new_range[1], new_range[2], length.out = n_new)
    out <- list(proposals)
    names(out) <- job$params
    dplyr::as_tibble(out)
  }
}

get_loss <- function(job, results, loss_fun) {
  losses <- numeric(nrow(results))
  for (i in seq_len(nrow(results))) {
    losses[i] <- loss_fun(
      results[i, job[["targets"]]],
      job[["targets_val"]]
    )
  }
  losses
}

mae <- function(values, targets) {
  sum(abs(values - targets)) / length(values)
}

rmse <- function(values, targets) {
  sqrt(sum((values - targets)^2) / length(values))
}

# must return a DF with exaclty ONE line or NULL
determ_noisy_end <- function(threshold, n_needed) {
  force(threshold)
  force(n_needed)
  function(job, results) {
    values <- results[[job$targets]]
    target <- job$targets_val
    dist <- vapply(values, mae, target = target, numeric(1))

    good_enough <- which(dist < threshold)

    if (length(good_enough) >= n_needed) {
      results <- results[good_enough, c(job$params, job$targets)]
      med_param <- quantile(results[[job$params]], 0.5, type = 1)
      med_row <- which(results[[job$params]] == med_param)
      return(results[med_row[1], c(job$params, job$targets)])
    } else {
      return(NULL)
    }
  }
}

determ_poly_end_rm0 <- function(threshold, poly_n = 3) {
  force(threshold)
  force(poly_n)
  function(calib_object, job, results) {
    values <- results[[job$targets]]
    params <- results[[job$params]]
    target <- job$targets_val

    mscale <- function(x, val) (x - mean(val)) / sd(val)
    munscale <- function(x, val) x * sd(val) + mean(val)

    complete_rows <- vctrs::vec_detect_complete(values) & values != 0
    values <- values[complete_rows]
    params <- params[complete_rows]

    s_v <- mscale(values, values)
    s_t <- mscale(target, values)
    s_p <- mscale(params, params)

    mod <- lm(s_v ~ poly(s_p, poly_n))
    loss_fun <- function(par)  abs(predict(mod, data.frame(s_p = par)) - s_t)
    predicted_param <- optimize(interval = range(s_p), f = loss_fun)

    s_newp <- predicted_param$minimum
    s_newv <- predict(mod, data.frame(s_p = s_newp))

    newp <- munscale(s_newp, params)

    oldp <- swfcalib::load_sideload(calib_object, job)
    swfcalib::save_sideload(calib_object, job, newp)

    if (is.null(oldp)) return(NULL)

    s_oldp <- mscale(oldp, params)
    s_oldv <- predict(mod, data.frame(s_p = s_oldp))

    newv <- munscale(s_newv, values)
    oldv <- munscale(s_oldv, values)

    if (abs(oldv - newv) < threshold && abs(newv - target) < threshold) {
      result <- data.frame(x = newp)
      names(result) <- job$params
      return(result)
    } else {
      return(NULL)
    }
  }
}


determ_poly_end <- function(threshold, poly_n = 3) {
  force(threshold)
  force(poly_n)
  function(calib_object, job, results) {
    values <- results[[job$targets]]
    params <- results[[job$params]]
    target <- job$targets_val

    mscale <- function(x, val) (x - mean(val)) / sd(val)
    munscale <- function(x, val) x * sd(val) + mean(val)

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    s_v <- mscale(values, values)
    s_t <- mscale(target, values)
    s_p <- mscale(params, params)

    mod <- lm(s_v ~ poly(s_p, poly_n))
    loss_fun <- function(par)  abs(predict(mod, data.frame(s_p = par)) - s_t)
    predicted_param <- optimize(interval = range(s_p), f = loss_fun)

    s_newp <- predicted_param$minimum
    s_newv <- predict(mod, data.frame(s_p = s_newp))

    newp <- munscale(s_newp, params)

    old_sideload <- swfcalib::load_sideload(calib_object, job)

    new_sideload <- list(center = newp, shrink = TRUE)
    swfcalib::save_sideload(calib_object, job, new_sideload)

    if (is.null(old_sideload)) return(NULL)
    oldp <- old_sideload$center

    s_oldp <- mscale(oldp, params)
    s_oldv <- predict(mod, data.frame(s_p = s_oldp))

    newv <- munscale(s_newv, values)
    oldv <- munscale(s_oldv, values)

    if (abs(oldv - newv) < threshold && abs(newv - target) < threshold) {
      result <- data.frame(x = newp)
      new_sideload$shrink <- FALSE
      swfcalib::save_sideload(calib_object, job, new_sideload)
      names(result) <- job$params
      return(result)
    } else {
      return(NULL)
    }
  }
}


make_shrink_proposer <- function(n_new, shrink = 2) {
  force(n_new)
  force(shrink)
  function(calib_object, job, results) {
    tar_range <- range(
      results[[job$params]][
        results[[".iteration"]] == max(results[[".iteration"]])
      ]
    )

    sideload <- swfcalib::load_sideload(calib_object, job)
    if (is.null(sideload)) {
      stop(
        "While making shrinked proposals: \n",
        "Sideload file with ID: `", job$targets, "` does not exist"
      )
    }

    if (!sideload$shrink)
      shrink <- 1

    spread <- (tar_range[2] - tar_range[1]) / shrink / 2

    proposals <- seq(
      max(sideload$center - spread, tar_range[1]),
      min(sideload$center + spread, tar_range[2]),
      length.out = n_new
    )

    proposals <- sample(proposals)

    out <- list(proposals)
    names(out) <- job$params
    dplyr::as_tibble(out)
  }
}

determ_ind_poly_end <- function(threshold, poly_n = 3) {
  force(threshold)
  force(poly_n)
  function(calib_object, job, results) {
    mscale <- function(x, val) (x - mean(val)) / sd(val)
    munscale <- function(x, val) x * sd(val) + mean(val)

    values <- c()
    params <- c()
    targets <- job$targets_val

    for (i in seq_along(job$targets)) {
      values <- c(values, results[[ job$targets[i] ]])
      params <- c(params, results[[ job$params[i] ]])
    }

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    s_v <- mscale(values, values)
    s_t <- mscale(targets, values)
    s_p <- mscale(params, params)

    mod <- lm(s_v ~ poly(s_p, poly_n))
    loss_fun <- function(par, t)  abs(predict(mod, data.frame(s_p = par)) - t)
    s_newp <- vapply(
      s_t,
      function(t) optimize(interval = range(s_p), f = loss_fun, t = t)$minimum,
      numeric(1)
    )
    s_newv <- predict(mod, data.frame(s_p = s_newp))
    newp <- munscale(s_newp, params)

    oldp <- swfcalib::load_sideload(calib_object, job)
    swfcalib::save_sideload(calib_object, job, newp)

    if (is.null(oldp)) return(NULL)

    s_oldp <- mscale(oldp, params)
    s_oldv <- predict(mod, data.frame(s_p = s_oldp))

    newv <- munscale(s_newv, values)
    oldv <- munscale(s_oldv, values)

    if (all(abs(oldv - newv) < threshold & abs(newv - targets) < threshold)) {
      result <- as.list(newp)
      names(result) <- job$params
      return(dplyr::as_tibble(result))
    } else {
      return(NULL)
    }
  }
}

make_ind_shrink_proposer <- function(n_new, shrink = 2) {
  force(n_new)
  force(shrink)
  function(calib_object, job, results) {
    sl_id <- paste0(job$targets, collapse = "")
    centers <- swfcalib::load_sideload(calib_object, job)
    if (is.null(centers)) {
      stop(
        "While making shrinked proposals: \n",
        "Sideload file with ID: `", job$targets, "` does not exist"
      )
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
}

determ_lin_poly_end <- function(thresholds, poly_n = 3) {
  force(thresholds)
  force(poly_n)
  function(calib_object, job, results) {
    mscale <- function(x, val) (x - mean(val)) / sd(val)
    munscale <- function(x, val) x * sd(val) + mean(val)

    values <- results[, job$targets]
    params <- results[, job$params]
    targets <- job$targets_val

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows, ]
    params <- params[complete_rows, ]

    s_v <- purrr::map_dfc(values, ~ mscale(.x, .x))
    s_p <- purrr::map_dfc(params, ~ mscale(.x, .x))
    s_t <- purrr::map2_dbl(targets, values, mscale)
    s_data <- dplyr::bind_cols(s_p, s_v)

    sfmla <- paste0(
      "cbind(",
      paste0(job$targets, collapse = ", "),
      ") ~ ",
      paste0(
        paste0("poly(", job$params, ", ", poly_n, ")"),
        collapse = " + "
      )
    )

    fmla <- as.formula(sfmla)
    mod <- lm(fmla, data = s_data)

    loss_fun <- function(par, t) {
      dat <- as.data.frame(as.list(par))
      names(dat) <- job$params
      out <- predict(mod, dat)
      sum((out - t)^2)
    }

    initial <- rep(0, ncol(params))
    s_newp <- optim(initial, loss_fun, t = s_t)$par

    dat <- as.data.frame(as.list(s_newp))
    names(dat) <- job$params
    s_newv <- predict(mod, dat)

    newp <- purrr::map2_dbl(s_newp, params, munscale)

    oldp <- swfcalib::load_sideload(calib_object, job)
    swfcalib::save_sideload(calib_object, job, newp)

    if (is.null(oldp)) return(NULL)

    s_oldp <- purrr::map2_dbl(oldp, params, mscale)
    dat <- as.data.frame(as.list(s_oldp))
    names(dat) <- job$params
    s_oldv <- predict(mod, dat)

    newv <- purrr::map2_dbl(s_newv, values, munscale)
    oldv <- purrr::map2_dbl(s_oldv, values, munscale)

    if (all(abs(oldv - newv) < thresholds) &&
        all(abs(newv - targets) < thresholds)) {
      result <- data.frame(as.list(newp))
      names(result) <- job$params
      return(result)
    } else {
      return(NULL)
    }
  }
}

make_dumb_end <- function(iter) {
  force(iter)
  function(calib_object, job, results) {
    if (swfcalib:::get_current_iteration(calib_object) >= iter) {
      params <- results[, job$params]
      result <- params[sample(nrow(params), 1), , drop = FALSE]
      names(result) <- job$params
      return(result)
    } else {
      return(NULL)
    }
  }
}

make_dumb_proposer <- function(n_new) {
  force(n_new)
  function(calib_object, job, results) {
    outs <- list()
    for (i in seq_along(job$params)) {
      tar_range <- range(results[[job$params[i]]])

      proposals <- seq(tar_range[1], tar_range[2], length.out = n_new)
      proposals <- sample(proposals)

      out <- list(proposals)
      names(out) <- job$params[i]
      outs[[i]] <- dplyr::as_tibble(out)
    }
    dplyr::bind_cols(outs)
  }
}

determ_trans_end <- function(retain_prop = 0.2, thresholds, n_enough) {
  force(retain_prop)
  force(thresholds)
  force(n_enough)

  function(calib_object, job, results) {
    # calculate new ranges if not done
    new_ranges <- list()
    for (i in seq_along(job$targets)) {
      params <- results[[ job$params[i] ]]
      values <- results[[ job$targets[i] ]]
      target <- job$targets_val[i]

      d <- dplyr::tibble(
        params = params,
        score = abs(values - target)
      )
      d <- dplyr::arrange(d, score)
      d <- head(d, ceiling(nrow(d) * retain_prop))
      new_ranges[[i]] <- range(d$params)
    }
    swfcalib::save_sideload(calib_object, job, new_ranges)

    # Enough close enough estimates?
    p_ok <- results[, c(job$params, job$targets)]
    for (j in seq_along(job$targets)) {
      values <- p_ok[[ job$targets[j] ]]
      target <- job$targets_val[j]
      thresh <- thresholds[j]

      p_ok <- p_ok[abs(values - target) < thresh, ]
    }

    if (nrow(p_ok) > n_enough) {
      res <- p_ok[, job$params]
      # get the n_tuple where all values are the closest to the median
      best <- dplyr::summarise(res, dplyr::across(
          dplyr::everything(),
          ~ abs(.x - median(.x)))
      )
      best <- which.min(rowSums(best))
      return(res[best, ])
    } else {
      return(NULL)
    }
  }
}

# propose new params based on ranges saved in a sideload
# ranges : list of range (numeric(2))
make_range_proposer <- function(n_new) {
  force(n_new)
  function(calib_object, job, results) {
    p_ranges <- swfcalib::load_sideload(calib_object, job)
    outs <- list()
    for (i in seq_along(job$params)) {
      proposals <- seq(p_ranges[[i]][1], p_ranges[[i]][2], length.out = n_new)
      proposals <- sample(proposals)
      out <- list(proposals)
      names(out) <- job$params[i]
      outs[[i]] <- dplyr::as_tibble(out)
    }
    dplyr::bind_cols(outs)
  }
}

make_sti_range_proposer <- function(n_new) {
  force(n_new)
  function(calib_object, job, results) {
    p_ranges <- swfcalib::load_sideload(calib_object, job)
    outs <- list()

    proposals <- seq(p_ranges[[1]][1], p_ranges[[1]][2], length.out = n_new)
    proposals <- sample(proposals)
    out <- list(proposals)
    names(out) <- job$params[1]
    outs[[1]] <- dplyr::as_tibble(out)

    proposals <- plogis(qlogis(proposals) + log(1.25))
    out <- list(proposals)
    names(out) <- job$params[2]
    outs[[2]] <- dplyr::as_tibble(out)

    dplyr::bind_cols(outs)
  }
}
