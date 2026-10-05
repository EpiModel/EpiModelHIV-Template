## Shared functions for cycle 2
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle2/`, after `c2_config.R` (which loads the
## cycle 1 `utils.R`). Section numbers (C2-Mx) refer to
## `R/E-restart_assessment/cycle2/results/c2_METHODS.md`.

# Project variables (C2-M1) ------------------------------------------------------

#' Add the project's calibration-target and outcome variables to the annual
#' list of year x chain matrices
#'
#' Definitions follow `EpiModelHIV::mutate_calibration_targets()` and
#' `R/D-interventions/outcomes.R`, computed as ratios of annual aggregates:
#'   i.prev.dx.X  = hiv.dx.X / num.X        (diagnosed prevalence)
#'   cc.vsupp.X   = hiv.supp.X / hiv.dx.X   (suppressed among diagnosed)
#'   ir100.sti    = 100 * incid / (num - inf) (per 100 person-years at risk)
#'   disease.mr100 = 100 * departures.AIDS / hiv.inf
#'   cml_incid.X  = hiv.incid.X (annual sums; windows are summed later)
#' @param Y named list of year x chain matrices (cycle 1 annual data)
add_project_vars <- function(Y) {
  for (g in c("B", "H", "W")) {
    Y[[paste0("i.prev.dx.", g)]] <- Y[[paste0("hiv.dx.", g)]] /
      Y[[paste0("num.", g)]]
    Y[[paste0("cc.vsupp.", g)]] <- Y[[paste0("hiv.supp.", g)]] /
      Y[[paste0("hiv.dx.", g)]]
    Y[[paste0("cml_incid.", g)]] <- Y[[paste0("hiv.incid.", g)]]
  }
  Y[["cml_incid"]] <- Y[["hiv.incid"]]
  for (sti in c("gono", "chla", "syph")) {
    Y[[paste0("ir100.", sti)]] <- 100 * Y[[paste0(sti, ".incid")]] /
      (Y[["num"]] - Y[[paste0(sti, ".inf")]])
  }
  Y[["disease.mr100"]] <- 100 * Y[["departures.AIDS"]] / Y[["hiv.inf"]]
  Y
}

#' Map from calibration target names to annual variable names
target_map <- c(
  cc.dx.B = "dx_frac.B", cc.dx.H = "dx_frac.H", cc.dx.W = "dx_frac.W",
  cc.vsupp.B = "cc.vsupp.B", cc.vsupp.H = "cc.vsupp.H",
  cc.vsupp.W = "cc.vsupp.W",
  ir100.gono = "ir100.gono", ir100.chla = "ir100.chla",
  ir100.syph = "ir100.syph",
  i.prev.dx.B = "i.prev.dx.B", i.prev.dx.H = "i.prev.dx.H",
  i.prev.dx.W = "i.prev.dx.W",
  cc.prep.B = "prep_cov.B", cc.prep.H = "prep_cov.H", cc.prep.W = "prep_cov.W",
  cc.prep = "prep_cov", disease.mr100 = "disease.mr100"
)

# Windows (C2-M2) ------------------------------------------------------------------

#' Window sums or means over years B + 1 ... B + L for every chain, from the
#' common restart (row = year after restart)
#' @return matrix [length(B_grid), n_chain]
window_from_x0 <- function(y, L, B_grid, fun = c("mean", "sum")) {
  fun <- match.arg(fun)
  cs <- rbind(0, apply(y, 2, cumsum))
  out <- t(vapply(B_grid, function(B) {
    (cs[B + L + 1, ] - cs[B + 1, ])
  }, numeric(ncol(y))))
  if (fun == "mean") out / L else out
}

#' Stationary reference for a window functional: all windows of length L
#' starting every `step` years from `start`, all chains (global mean)
#' @return c(mu, var)
window_ref <- function(y, L, start, step = 1, fun = c("mean", "sum")) {
  fun <- match.arg(fun)
  starts <- seq(start, nrow(y) - L + 1, by = step)
  cs <- rbind(0, apply(y, 2, cumsum))
  M <- vapply(starts, function(s) cs[s + L, ] - cs[s, ], numeric(ncol(y)))
  if (fun == "mean") M <- M / L
  c(mu = mean(M), var = mean((M - mean(M))^2))
}

# Relaxation (C2-M3) ------------------------------------------------------------------

#' Tolerance times from the cycle 1 relaxation fits (same method as step 04)
fit_times <- function(y, pi_rows, fit_t, eps, deltas) {
  pm <- pi_moments(y, pi_rows)
  cm <- cross_moments(y[fit_t, , drop = FALSE])
  fv <- fit_var_relax(fit_t, cm$v / pm$s2)
  fm <- fit_mean_relax(fit_t, (cm$m - pm$mu) / sqrt(pm$s2))
  list(
    t_var = vapply(eps, function(e) t_from_fit(function(t) 1 - fv$fn(t), e),
      numeric(1)),
    t_mean = vapply(deltas, function(d) t_from_fit(fm$fn, d), numeric(1)),
    fv = fv, fm = fm
  )
}

#' Stretched-exponential alternative for the variance ratio:
#' r(t) = 1 - c exp(-(t / tau)^beta)
fit_var_stretched <- function(t, r) {
  f <- function(p, t) 1 - p[1] * exp(-(t / p[2])^p[3])
  best <- NULL
  for (s in list(c(1, 10, 1), c(1, 30, 1.5), c(1, 5, 0.6), c(1, 60, 2))) {
    fit <- tryCatch(
      minpack.lm::nls.lm(s, c(0, 0.1, 0.2), c(2, 1000, 4),
        fn = function(p) r - f(p, t),
        control = minpack.lm::nls.lm.control(maxiter = 500)),
      error = function(e) NULL)
    if (!is.null(fit) && (is.null(best) || fit$deviance < best$deviance)) {
      best <- fit
    }
  }
  p <- best$par
  list(coef = p, fn = function(t) f(p, t))
}

#' Nonparametric alternative: isotonic (monotone non-decreasing) regression of
#' the variance ratio, then the first year the fit reaches 1 - eps
#'
#' A monotone fit pools adjacent noisy years, so the first crossing is far
#' less sensitive to noise than the raw crossing. It assumes r(t) does not
#' overshoot 1, which holds within noise for the variance ratios here.
iso_time <- function(t, r, eps) {
  f <- stats::isoreg(t, r)$yf
  hit <- which(f >= 1 - eps)
  if (!length(hit)) Inf else t[min(hit)]
}

#' Lower-bound-based time: first horizon on the grid after which the lower
#' bound on ICC stays <= eps. Because ICC >= bound, the true time is at
#' least this value (C2-M4).
t_from_bound <- function(h, lb, eps) {
  o <- order(h)
  h <- h[o]
  lb <- lb[o]
  bad <- which(lb > eps)
  if (!length(bad)) return(h[1])
  if (max(bad) == length(h)) return(Inf)
  h[max(bad) + 1]
}
