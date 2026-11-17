## Gaussian Process Stopping Rules for swfcalib
##
## Adrien's Gaussian process (GP) calibration, ported from
## `R/Z-calibration/het_gp_process.R` in LA-PrEP-CABARET-CEA (`v3.3.x` at
## c8016919; the same code as LA-PrEP-Merck `alg_calib`). Each `determ_gp_*`
## function returns a swfcalib `get_result`: it fits one heteroskedastic GP
## (`hetGP::mleHetGP`, Matern 5/2 kernel) per target over every run of the wave
## so far, on parameters scaled to the tested range, and solves the emulator's
## mean for the target. A job whose design does not reach its target saves a
## new design as a sideload, and `proposer_load_sideload()` hands it to swfcalib
## as the next iteration's proposals.
##
## swfcalib calls `get_result` for every job of the wave at every iteration,
## finished or not, with all the wave's runs, so a finished job is refitted
## each time and can reopen.
##
## The functions stored in `calib_object` run on the HPC without this script's
## objects: everything they use must be an argument or defined inside them.
##
## Changes from the original:
##
## - `determ_gp_end_single()` takes the size of its fallback design as
##   arguments instead of inferring it from the number of distinct values
##   tested, which grows once a job has run twice, and drops incomplete runs
##   with `stats::complete.cases()` rather than `vctrs`. It accepts the
##   closest value when the GP mean comes within the target's tolerance
##   without crossing it, can fit on the design points whose runs are all
##   above zero (the STI jobs), and widens its range toward the target rather
##   than jumping to the whole extended range.
## - `determ_gp_end_joint()` replaces `determ_gp_end_single3()`. It takes any
##   number of parameters (the original fixed three), drops incomplete runs,
##   and solves on residuals relative to each target, because the three race
##   groups' targets differ severalfold within a city. It also refuses a
##   solution on the edge of the tested box or one that misses a target by
##   more than `max_rel_resid` on the emulator: it saves a wider design and
##   fits again on both. The original returned on its first pass. The solver
##   starts from the best design points as well as the center of the box.
##
## This script should not be run directly. But `sourced` from
## `swfcalib_config.R`.

#' swfcalib proposer that returns the design a job saved as its sideload.
proposer_load_sideload <- function(calib_object, job, results) {
  swfcalib::load_sideload(calib_object, job)$proposals
}

#' One-parameter design: `n_points` evenly spaced values over `rng`, each
#' repeated `n_reps` times, in random order.
make_grid_design <- function(param, rng, n_points, n_reps) {
  x <- sample(rep(seq(rng[1], rng[2], length.out = n_points), n_reps))
  stats::setNames(dplyr::tibble(x), param)
}

#' Several-parameter design: a maximin Latin hypercube of `n_points` points
#' over the box `ranges` (one `c(min, max)` per parameter), each repeated
#' `n_reps` times.
make_lhs_design <- function(params, ranges, n_points, n_reps) {
  u <- lhs::maximinLHS(n_points, length(params))
  cols <- lapply(seq_along(params), function(i) {
    rep(ranges[[i]][1] + u[, i] * diff(ranges[[i]]), times = n_reps)
  })
  stats::setNames(dplyr::as_tibble(cols, .name_repair = "minimal"), params)
}

#' GP stopping rule for a job with one parameter and one target.
#'
#' Fits the GP over the tested range and looks for the value whose predicted
#' mean equals the target (`uniroot`, so it assumes one crossing, which holds
#' for a monotone response). If the mean never crosses the target but comes
#' within `tol` of it, the closest value is accepted: a job once used all its
#' iterations on a target that was within tolerance over a quarter of the
#' widened range and crossed only at its top (November 2026). Otherwise the
#' tested range does not reach the target: the next design is `n_points`
#' values over the range widened by `widen` times its width on the side toward
#' the target, within `extended_range`, `n_reps` times each, and the job stays
#' open.
#'
#' With `positive_only`, the GP is fitted first on the design points at which
#' every run kept the outcome above zero, if at least `min_points` remain, and
#' on all of them otherwise or if that finds nothing. A bacterial STI's case
#' rate is zero below the per-act probability at which its epidemic dies out
#' and rises steeply above it, and a GP fitted across that kink averages the
#' flat part into the steep one. In the first-pass STI runs of a four-city
#' calibration (November 2026), this put the gonorrhea fits 7 to 44 percent
#' above their targets (by a hinge fit through the runs); fitting on the
#' positive design points only put them within 6 percent.
#'
#' @param extended_range The widest range a design may reach, `c(min, max)`.
#' @param n_points,n_reps Size of the next design.
#' @param tol The target's tolerance (`target_tolerance()`), or `NA` to accept
#'   only a crossing.
#' @param positive_only Fit on the all-positive design points first.
#' @param min_points Fewest all-positive design points worth fitting on.
#' @param widen Fraction of the range width added on the side toward the
#'   target when the design does not reach it.
determ_gp_end_single <- function(extended_range, n_points, n_reps, tol = NA,
                                 positive_only = FALSE, min_points = 6,
                                 widen = 1) {
  force(extended_range)
  force(n_points)
  force(n_reps)
  force(tol)
  force(positive_only)
  force(min_points)
  force(widen)
  function(calib_object, job, results) {
    mscale <- function(x, rnge) (x - rnge[1]) / diff(rnge)
    munscale <- function(x, rnge) x * diff(rnge) + rnge[1]

    par_name <- job$params[1]
    target <- unname(job$targets_val[1])
    keep <- stats::complete.cases(results[c(par_name, job$targets[1])])
    params <- results[[par_name]][keep]
    values <- results[[job$targets[1]]][keep]

    # The crossing of the GP mean with the target, or else the closest value
    # if it is within `tol`. `miss_ends` is the mean minus the target at the
    # two ends of the range fitted.
    solve_gp <- function(p, v) {
      rng <- range(p)
      mod <- hetGP::mleHetGP(
        matrix(mscale(p, rng), ncol = 1), v,
        covtype = "Matern5_2", eps = 1e-6
      )
      f_miss <- function(x) {
        stats::predict(mod, matrix(x, ncol = 1))$mean - target
      }
      grid <- seq(0, 1, length.out = 201)
      miss <- f_miss(grid)
      out <- list(par = NA_real_, how = NA_character_, rng = rng,
                  miss_ends = miss[c(1, length(grid))])
      root <- tryCatch(
        stats::uniroot(f_miss, interval = c(0, 1))$root,
        error = function(e) NA
      )
      if (!is.na(root)) {
        out$par <- munscale(root, rng)
        out$how <- "crossing"
      } else if (!is.na(tol) && min(abs(miss)) <= tol) {
        out$par <- munscale(grid[which.min(abs(miss))], rng)
        out$how <- paste0("closest, within tolerance (miss ",
                          signif(miss[which.min(abs(miss))], 3), ")")
      }
      out
    }

    sol <- list(par = NA_real_)
    if (positive_only) {
      all_pos <- as.logical(stats::ave(as.numeric(values > 0), params,
                                       FUN = min))
      if (length(unique(params[all_pos])) >= min_points) {
        sol <- solve_gp(params[all_pos], values[all_pos])
        if (!is.na(sol$par)) {
          sol$how <- paste(sol$how, "on the all-positive design points")
        }
      }
    }
    if (is.na(sol$par)) sol <- solve_gp(params, values)

    if (!is.na(sol$par)) {
      # Kept so that a job that reopens at a later iteration runs this design
      # again
      swfcalib::save_sideload(
        calib_object, job,
        list(proposals = stats::setNames(dplyr::tibble(params), par_name))
      )
      message(job$id, ": GP solution ", par_name, " = ", signif(sol$par, 4),
              " (", sol$how, ")")
      return(stats::setNames(dplyr::tibble(sol$par), par_name))
    }

    # Widen on the side whose end comes closer to the target, which for a
    # monotone response is the side the target lies beyond.
    rng <- sol$rng
    w <- diff(rng)
    if (abs(sol$miss_ends[1]) < abs(sol$miss_ends[2])) {
      next_range <- c(max(extended_range[1], rng[1] - widen * w), rng[2])
    } else {
      next_range <- c(rng[1], min(extended_range[2], rng[2] + widen * w))
    }
    message(
      job$id, ": the GP mean does not reach ", signif(target, 4), " over ",
      paste(signif(rng, 4), collapse = " to "), "; next design over ",
      paste(signif(next_range, 4), collapse = " to ")
    )
    swfcalib::save_sideload(
      calib_object, job,
      list(proposals = stats::setNames(
        dplyr::tibble(sample(rep(
          seq(next_range[1], next_range[2], length.out = n_points),
          n_reps
        ))),
        par_name
      ))
    )
    NULL
  }
}

#' GP stopping rule for a job with several parameters and as many targets.
#'
#' Fits one GP per target over the tested box and solves the targets jointly
#' with `minpack.lm::nls.lm`, on residuals relative to each target, from
#' several starting points. The
#' solution is accepted if it lies inside the box and every relative residual
#' is at most `max_rel_resid`. Otherwise the next design is a Latin hypercube
#' over a wider box, widened by `widen` times its width on the sides the
#' solution reached (on every side if it reached none), and the job stays
#' open. The next fit uses both designs.
#'
#' @param n_points,n_reps Size of the next design.
#' @param max_rel_resid Largest relative miss of the emulator's mean accepted.
#' @param widen Fraction of the box width added on a side.
#' @param n_starts Number of design points, besides the center, the solver
#'   starts from.
#' @param design_fn `make_lhs_design`, passed so it travels with the function.
determ_gp_end_joint <- function(n_points, n_reps, max_rel_resid = 0.05,
                                widen = 0.5, n_starts = 5,
                                design_fn = make_lhs_design) {
  force(n_points)
  force(n_reps)
  force(max_rel_resid)
  force(widen)
  force(n_starts)
  force(design_fn)
  function(calib_object, job, results) {
    mscale <- function(x, rnge) (x - rnge[1]) / diff(rnge)
    munscale <- function(x, rnge) x * diff(rnge) + rnge[1]

    par_names <- job$params
    targets <- unname(job$targets_val)
    n_par <- length(par_names)
    keep <- stats::complete.cases(results[c(par_names, job$targets)])
    results <- results[keep, ]

    par_ranges <- lapply(results[par_names], range)
    x <- mapply(mscale, results[par_names], par_ranges)
    mods <- lapply(job$targets, function(tn) {
      hetGP::mleHetGP(x, results[[tn]], covtype = "Matern5_2", eps = 1e-6)
    })
    resid <- function(u) {
      xm <- matrix(pmin(pmax(u, 0), 1), nrow = 1)
      vapply(seq_along(mods), function(k) {
        (stats::predict(mods[[k]], xm)$mean - targets[k]) / targets[k]
      }, numeric(1))
    }
    # Start the solver at the center of the box and at the `n_starts` design
    # points whose runs came closest to the targets on average, and keep the
    # solution with the smallest largest residual. With the center alone, a
    # three-parameter HIV job (November 2026) stopped on the edge of the box
    # three times and used all four iterations, though its first iteration's
    # GPs already held a solution with no residual inside the box.
    pts <- stats::aggregate(results[job$targets], results[par_names], mean)
    pt_resid <- sweep(sweep(as.matrix(pts[job$targets]), 2, targets), 2,
                      targets, "/")
    best <- order(rowSums(pt_resid^2))[seq_len(min(n_starts, nrow(pts)))]
    starts <- rbind(
      rep(0.5, n_par),
      matrix(mapply(mscale, pts[best, par_names, drop = FALSE], par_ranges),
             ncol = n_par)
    )
    fits <- lapply(seq_len(nrow(starts)), function(i) {
      minpack.lm::nls.lm(
        par = starts[i, ], fn = resid,
        lower = rep(0, n_par), upper = rep(1, n_par)
      )
    })
    worst <- vapply(fits, function(f) max(abs(resid(f$par))), numeric(1))
    u_star <- fits[[which.min(worst)]]$par
    rel_resid <- resid(u_star)
    par_star <- stats::setNames(mapply(munscale, u_star, par_ranges), par_names)
    message(
      job$id, ": GP solution ",
      paste(par_names, signif(par_star, 4), sep = " = ", collapse = ", "),
      "; relative residuals ", paste(signif(rel_resid, 3), collapse = ", ")
    )

    at_low <- u_star < 0.01
    at_high <- u_star > 0.99
    if (!any(at_low | at_high) && max(abs(rel_resid)) <= max_rel_resid) {
      return(dplyr::as_tibble(as.list(par_star)))
    }

    if (!any(at_low | at_high)) {
      at_low[] <- TRUE
      at_high[] <- TRUE
    }
    box <- lapply(seq_len(n_par), function(i) {
      r <- par_ranges[[i]]
      w <- diff(r)
      c(
        if (at_low[i]) max(r[1] / 2, r[1] - widen * w) else r[1],
        if (at_high[i]) r[2] + widen * w else r[2]
      )
    })
    message(
      job$id, ": solution not accepted; next design over ",
      paste(
        par_names,
        vapply(box, \(b) paste(signif(b, 4), collapse = " to "), ""),
        sep = " ", collapse = ", "
      )
    )
    swfcalib::save_sideload(
      calib_object, job,
      list(proposals = design_fn(par_names, box, n_points, n_reps))
    )
    NULL
  }
}
