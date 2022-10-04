make_partition_proposer <- function(partitions, allowed_range = c(-Inf, Inf)) {
  if (partitions < 3)
    stop("`partitions` must be greater than or equal to 3")

  function(job, results) {
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
merge_proposals <- function(proposals) {
  max_rows <- max(vapply(proposals, nrow, numeric(1)))
  proposals <- lapply(proposals, function(d) {
    missing_rows <- max_rows - nrow(d)
    if (missing_rows > 0)
      d <- dplyr::bind_rows(d, dplyr::sample_n(d, missing_rows, replace = TRUE))
    d
  })
  dplyr::bind_cols(proposals)
}

fill_proposals <- function(proposals, default_proposal) {
  missing_cols <- setdiff(names(default_proposal), names(proposals))
  merge_proposals(list(proposals, default_proposal[, missing_cols]))
}


# ------------------------------------------------------------------------------
make_noisy_proposer <- function(n_new, n_best) {
  force(n_new)
  force(n_best)
  function(job, results) {
    values <- results[[job$targets]]
    target <- job$targets_val

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

make_poly_proposer <- function(n_new, poly_n = 4) {
  force(n_new)
  force(poly_n)
  function(job, results) {
    values <- results[[job$targets]]
    target <- job$targets_val
    param <- results[[job$params]]

    tar_range <- range(
      results[[job$params]][
        results[[".iteration"]] == max(results[[".iteration"]])])

    spread <- (tar_range[2] - tar_range[1]) / 4

    mod <- lm(param ~ poly(values, poly_n))
    pp <- predict(mod, data.frame(values = target), target = "response", se = T)
    proposals <- seq(pp$fit - spread, pp$fit + spread, length.out = n_new)
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
