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
    predicted_param <- optimize(range(-3, 3), f = loss_fun)

    s_newp <- predicted_param$minimum
    s_newv <- predict(mod, data.frame(s_p = s_newp))

    newp <- munscale(s_newp, params)

    oldp <- swfcalib::load_sideload(calib_object, id = job$targets)
    swfcalib::save_sideload(calib_object, x = newp, id = job$targets)

    if (is.null(oldp)) return(NULL)

    s_oldp <- mscale(oldp, params)
    s_oldv <- predict(mod, data.frame(s_p = s_oldp))

    newv <- munscale(s_newv, values)
    oldv <- munscale(s_oldv, values)

    swfcalib::save_sideload(calib_object, x = newp, id = job$targets)

    if (abs(oldv - newv) < threshold && abs(newv - target) < threshold) {
      result <- data.frame(x = newp)
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

    spread <- (tar_range[2] - tar_range[1]) / shrink / 2
    center <- swfcalib::load_sideload(calib_object, id = job$targets)
    if (is.null(center)) {
      stop(
        "While making shrinked proposals: \n",
        "Sideload file with ID: `", job$targets, "` does not exist"
      )
    }

    proposals <- seq(
      max(center - spread, tar_range[1]),
      min(center + spread, tar_range[2]),
      length.out = n_new
    )
    out <- list(proposals)
    names(out) <- job$params
    dplyr::as_tibble(out)
  }
}
