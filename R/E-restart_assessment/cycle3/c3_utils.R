## Shared functions for cycle 3
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle3/`, after `c3_config.R` (which loads the
## cycle 1 `utils.R` and the cycle 2 `c2_utils.R`). Section numbers (C3-Mx)
## refer to `R/E-restart_assessment/cycle3/results/c3_METHODS.md`; Mx to the
## cycle 1 `METHODS.md`.

# Annual data (C3-M1) --------------------------------------------------------------

#' Annual values of one weekly variable
#'
#' `x` is ordered by sim then time, `steps` rows per year. Weeks with no
#' record (the initialisation step of a cold start) are left out: a stock is
#' the mean of the recorded weeks, a flow the sum rescaled to a full year
#' (sum * steps / recorded weeks), so that year 1 of a cold start (51
#' simulated weeks) is on the same scale as the other years.
#' @param kind "flow" or "stock"
#' @return matrix [n_years, n_sims]
annualise <- function(x, kind, n_years, n_sims, steps = year_steps) {
  dim(x) <- c(steps, n_years * n_sims)
  n_ok <- colSums(!is.na(x))
  s <- colSums(x, na.rm = TRUE)
  out <- if (kind == "flow") s * steps / n_ok else s / n_ok
  matrix(out, n_years, n_sims)
}

#' Derived variables as ratios of annual aggregates (M1.3)
#'
#' Same names and definitions as cycle 1 (`01_prepare_annual.R`): prev,
#' incid_rate (per 100 person-years at risk), dx_frac, supp_frac and
#' prep_cov, in total and by race, then STI prevalence and STI incidence per
#' 100 person-years. c3_01 checks that it reproduces the cycle 1 values.
#' @param A named list of annual matrices of the raw variables
derive_vars <- function(A) {
  out <- list()
  for (g in c("", ".B", ".H", ".W")) {
    v <- function(n) paste0(n, g)
    out[[v("prev")]] <- A[[v("hiv.inf")]] / A[[v("num")]]
    out[[v("incid_rate")]] <- 100 * A[[v("hiv.incid")]] /
      (A[[v("num")]] - A[[v("hiv.inf")]])
    out[[v("dx_frac")]] <- A[[v("hiv.dx")]] / A[[v("hiv.inf")]]
    out[[v("supp_frac")]] <- A[[v("hiv.supp")]] / A[[v("hiv.inf")]]
    out[[v("prep_cov")]] <- A[[v("prep")]] / A[[v("prep.indic")]]
  }
  for (sti in c("gono", "chla", "syph")) {
    out[[paste0(sti, "_prev")]] <- A[[paste0(sti, ".inf")]] / A[["num"]]
    out[[paste0(sti, "_ir")]] <- 100 * A[[paste0(sti, ".incid")]] / A[["num"]]
  }
  out
}

#' Project variables: cycle 2 (C2-M1, `add_project_vars()`), plus the annual
#' analogue of the new targets (EpiModelHIV-p 6e6bff15) when new diagnoses
#' are recorded:
#'   ir100.hiv.dx.X = 100 * new diagnoses / mean(num.X - hiv.dx.X - dx.incid.X)
#' The weekly mean of hiv.dx.incid is its (full-year) annual sum / year_steps.
add_project_vars_c3 <- function(Y) {
  Y <- add_project_vars(Y)
  if (all(paste0("hiv.dx.incid.", c("B", "H", "W")) %in% names(Y))) {
    for (g in c("B", "H", "W")) {
      Y[[paste0("ir100.hiv.dx.", g)]] <- 100 * Y[[paste0("hiv.dx.incid.", g)]] /
        (Y[[paste0("num.", g)]] - Y[[paste0("hiv.dx.", g)]] -
          Y[[paste0("hiv.dx.incid.", g)]] / year_steps)
    }
  }
  Y
}

#' Aggregation rules of the project variables, for the dictionary
project_rules <- function() {
  g <- c("B", "H", "W")
  c(
    setNames(paste0("hiv.dx.", g, " / num.", g), paste0("i.prev.dx.", g)),
    setNames(paste0("hiv.supp.", g, " / hiv.dx.", g), paste0("cc.vsupp.", g)),
    setNames(paste0("hiv.incid.", g, " (annual sum)"), paste0("cml_incid.", g)),
    cml_incid = "hiv.incid (annual sum)",
    setNames(paste0("100 * ", c("gono", "chla", "syph"), ".incid / (num - ",
      c("gono", "chla", "syph"), ".inf)"),
      paste0("ir100.", c("gono", "chla", "syph"))),
    disease.mr100 = "100 * departures.AIDS / hiv.inf",
    setNames(paste0("100 * hiv.dx.incid.", g, " / (num.", g, " - hiv.dx.", g,
      " - hiv.dx.incid.", g, " / 52)"), paste0("ir100.hiv.dx.", g))
  )
}

#' Calibration targets -> annual variables (cycle 2 map + the new targets)
target_map_c3 <- c(target_map,
  ir100.hiv.dx.B = "ir100.hiv.dx.B", ir100.hiv.dx.H = "ir100.hiv.dx.H",
  ir100.hiv.dx.W = "ir100.hiv.dx.W")

# Relaxation after a cold start (C3-M3) ---------------------------------------------

#' Least squares with several starting values (Levenberg-Marquardt); returns
#' the fit with the smallest deviance, NULL if every start fails
lm_best <- function(f, t, y, starts, lower, upper) {
  best <- NULL
  for (s in starts) {
    s <- pmin(pmax(s, lower), upper)
    fit <- tryCatch(
      minpack.lm::nls.lm(s, lower, upper,
        fn = function(p) y - f(p, t),
        control = minpack.lm::nls.lm.control(maxiter = 1000)
      ),
      error = function(e) NULL
    )
    if (!is.null(fit) && (is.null(best) || fit$deviance < best$deviance)) {
      best <- fit
    }
  }
  best
}

#' Relaxation of the standardised mean offset o(t) after a cold start
#'
#' Same three models as cycle 1 (`fit_mean_relax`, M2.5):
#'   (a) A1 exp(-t / tau1); (b) (a) + A2 exp(-t / tau2);
#'   (c) A exp(-t / tau) cos(omega t + phi).
#' A cold start is much further from pi than x0 was (tens of SD in the
#' first years), so amplitudes may reach +-1e4 (they are extrapolations to
#' t = 0) and the starting values come from the data: the fast amplitude from
#' the first fitted year, the slow one from the mean offset over years 40-60.
#' AIC selection; a more complex model must improve the AIC by at least 2
#' (residuals are autocorrelated, so the AIC is indicative only).
#' @param t years (starting at FIT_START), o offsets in SD_pi units
#' @return list(model, coef, aic, fn)
fit_mean_relax_c3 <- function(t, o) {
  fa <- function(p, t) p[1] * exp(-t / p[2])
  fb <- function(p, t) p[1] * exp(-t / p[2]) + p[3] * exp(-t / p[4])
  fc <- function(p, t) p[1] * exp(-t / p[2]) * cos(p[3] * t + p[4])
  A <- 1e4
  t1 <- t[1]
  o1 <- o[1]
  mid <- t >= 40 & t <= 60
  o_mid <- if (any(mid)) mean(o[mid]) else o[ceiling(length(o) / 2)]
  st_a <- lapply(c(2, 10, 30, 60), function(tau) c(o1 * exp(t1 / tau), tau))
  st_b <- list()
  for (tf in c(1, 3, 8)) {
    for (ts in c(20, 40, 80)) {
      As <- o_mid * exp(50 / ts)
      Af <- (o1 - As * exp(-t1 / ts)) * exp(t1 / tf)
      st_b[[length(st_b) + 1]] <- c(Af, tf, As, ts)
    }
  }
  st_c <- list()
  for (tau in c(10, 30, 60)) {
    for (om in c(0.03, 0.1, 0.3)) {
      st_c[[length(st_c) + 1]] <- c(o1 * exp(t1 / tau), tau, om, 0)
    }
  }
  fits <- list(
    `1exp` = lm_best(fa, t, o, st_a, c(-A, 0.1), c(A, 1000)),
    `2exp` = lm_best(fb, t, o, st_b, c(-A, 0.1, -A, 0.1), c(A, 1000, A, 1000)),
    damped_cos = lm_best(fc, t, o, st_c, c(-A, 0.1, 0, -pi),
      c(A, 1000, pi, pi))
  )
  f_list <- list(`1exp` = fa, `2exp` = fb, damped_cos = fc)
  k <- c(`1exp` = 2, `2exp` = 4, damped_cos = 4)
  n <- length(o)
  aic <- vapply(names(fits), function(m) {
    if (is.null(fits[[m]])) Inf else n * log(fits[[m]]$deviance / n) + 2 * k[m]
  }, numeric(1))
  m <- if (min(aic[-1]) < aic[1] - 2) names(which.min(aic)) else "1exp"
  p <- fits[[m]]$par
  if (m == "2exp" && p[2] > p[4]) p <- p[c(3, 4, 1, 2)] # fast component first
  list(model = m, coef = p, aic = aic, fn = function(t) f_list[[m]](p, t))
}

#' Relaxation of the variance ratio r(t) = v(t) / v_pi after a cold start
#'
#' Cycle 1 models (`fit_var_relax`): 1 - c1 exp(-t / tau1), optionally
#' - c2 exp(-t / tau2). Unlike runs from one common state, independent
#' cold-start chains can be MORE dispersed than pi early on (r > 1), so c1
#' and c2 may be negative. Starts and bounds as in `fit_mean_relax_c3`.
#' @return list(model, coef, aic, fn) with fn(t) = fitted r(t)
fit_var_relax_c3 <- function(t, r) {
  f1 <- function(p, t) 1 - p[1] * exp(-t / p[2])
  f2 <- function(p, t) 1 - p[1] * exp(-t / p[2]) - p[3] * exp(-t / p[4])
  C <- 1e4
  t1 <- t[1]
  d1 <- 1 - r[1]
  mid <- t >= 40 & t <= 60
  d_mid <- if (any(mid)) mean(1 - r[mid]) else 0
  st1 <- lapply(c(1, 5, 20, 60), function(tau) c(d1 * exp(t1 / tau), tau))
  st2 <- list()
  for (tf in c(1, 3, 8)) {
    for (ts in c(20, 40, 80)) {
      cs <- d_mid * exp(50 / ts)
      cf <- (d1 - cs * exp(-t1 / ts)) * exp(t1 / tf)
      st2[[length(st2) + 1]] <- c(cf, tf, cs, ts)
    }
  }
  fit1 <- lm_best(f1, t, r, st1, c(-C, 0.1), c(C, 1000))
  fit2 <- lm_best(f2, t, r, st2, c(-C, 0.1, -C, 0.1), c(C, 1000, C, 1000))
  n <- length(r)
  aic <- function(fit, k) n * log(fit$deviance / n) + 2 * k
  a1 <- if (is.null(fit1)) Inf else aic(fit1, 2)
  a2 <- if (is.null(fit2)) Inf else aic(fit2, 4)
  if (a2 < a1 - 2) {
    p <- fit2$par
    if (p[2] > p[4]) p <- p[c(3, 4, 1, 2)]
    list(model = "2exp", coef = p, aic = c(a1, a2), fn = function(t) f2(p, t))
  } else {
    p <- fit1$par
    list(model = "1exp", coef = c(p, NA, NA), aic = c(a1, a2),
      fn = function(t) f1(p, t))
  }
}

#' First year of the tail window used for the mean-relaxation fit (C3-M3)
#'
#' The first decades after a cold start are a nonlinear transient (epidemic
#' overshoot, replacement of the initial cohort) that a sum of two
#' exponentials does not describe, and least squares would spend the fit on
#' offsets of 10-20 SD there. The tolerance times only depend on the tail,
#' where the relaxation is close to linear. The fit therefore starts at the
#' first year after which the running mean (width w) of |o| stays <= level.
#' @param t years, o offsets (same length)
#' @return a year of `t`
tail_start <- function(t, o, level, w = 5) {
  os <- as.vector(stats::filter(abs(o), rep(1 / w, w), sides = 2))
  os[is.na(os)] <- abs(o)[is.na(os)]
  over <- which(os > level)
  if (!length(over)) t[1] else t[min(max(over) + 1, length(t))]
}

#' Tolerance time of the mean from a tail fit (C3-M3)
#'
#' From the start of the tail window t_a onwards the fitted curve is used.
#' Before t_a the offset is several SD, far above the noise, so exceedances
#' of large tolerances are read from the running mean (width w) of the data.
#' T = year after the last exceedance of either.
#' @param t,o all years from 1 (or 0) and their offsets; fm a mean fit
t_tol <- function(t, o, fm, t_a, d, w = 5) {
  fit_part <- t_from_fit(function(tt) ifelse(tt >= t_a, fm$fn(tt), 0), d)
  os <- as.vector(stats::filter(abs(o), rep(1 / w, w), sides = 2))
  os[is.na(os)] <- abs(o)[is.na(os)]
  pre <- which(t < t_a & os > d)
  max(fit_part, if (length(pre)) t[max(pre)] + 1 else 0)
}

#' Tolerance times after a cold start (C3-M3)
#'
#' Fits r(t) over `fit_t` and o(t) over the tail window of `fit_t`
#' (`tail_start`), against the pi moments of the same chains (years
#' `pi_rows`), and returns
#'   T_var(eps)    : fitted |r(t) - 1| stays <= eps afterwards;
#'   T_mean(delta) : |o(t)| stays <= delta afterwards (`t_tol`);
#'   o_fit         : fitted offset at the years `at` (residual bias, C3-M4),
#'                   NA before the tail window.
#' `tail_level = Inf` fits o(t) over the whole of `fit_t` (as cycle 1).
#' @param pi_ref optional list(mu, s2) to use an external pi reference
cold_times <- function(y, fit_t, pi_rows, eps, deltas, at = integer(0),
                       pi_ref = NULL, tail_level = TAIL_LEVEL) {
  pm <- if (is.null(pi_ref)) pi_moments(y, pi_rows) else pi_ref
  t_all <- seq_len(max(fit_t))
  cm <- cross_moments(y[t_all, , drop = FALSE])
  o_all <- (cm$m - pm$mu) / sqrt(pm$s2)
  in_fit <- t_all >= fit_t[1]
  t_f <- t_all[in_fit]
  o <- o_all[in_fit]
  t_a <- if (is.finite(tail_level)) tail_start(t_f, o, tail_level) else t_f[1]
  keep <- t_f >= t_a
  fv <- fit_var_relax_c3(t_f, cm$v[in_fit] / pm$s2)
  fm <- fit_mean_relax_c3(t_f[keep], o[keep])
  list(
    t_var = vapply(eps, function(e) t_from_fit(function(t) 1 - fv$fn(t), e),
      numeric(1)),
    t_mean = vapply(deltas, function(d) t_tol(t_all, o_all, fm, t_a, d),
      numeric(1)),
    o_fit = ifelse(at >= t_a, fm$fn(at), NA_real_),
    t_tail = t_a,
    fv = fv, fm = fm
  )
}

# Two stationary laws (C3-M2) --------------------------------------------------------

#' Per-chain sums over the reference years, the sufficient statistics of the
#' pooled mean and variance of any group of chains
#' @return matrix [n_chain, 2]: sum of y, sum of y^2
chain_sums <- function(y, rows) {
  yy <- y[rows, , drop = FALSE]
  cbind(colSums(yy), colSums(yy^2))
}

#' Pooled moments (global mean) of a group of chains from their sums
group_moments <- function(S, n_t) {
  n <- nrow(S) * n_t
  mu <- sum(S[, 1]) / n
  c(mu = mu, s2 = sum(S[, 2]) / n - mu^2)
}

#' Two-sample statistics between chain groups a and b
#' @return c(d_mean = mean difference in pooled SD units, log_vr = log
#'   variance ratio a / b)
two_sample_stats <- function(Sa, Sb, n_t) {
  a <- group_moments(Sa, n_t)
  b <- group_moments(Sb, n_t)
  c(d_mean = unname((a["mu"] - b["mu"]) / sqrt((a["s2"] + b["s2"]) / 2)),
    log_vr = unname(log(a["s2"] / b["s2"])))
}

#' Chain-permutation tests of equal means and variances, per variable and
#' global (C3-M2)
#'
#' Under H0 (same stationary law) the chains of the two datasets are
#' exchangeable, so relabelling whole chains gives an exact null. Per
#' variable: two-sided permutation p-values. Global: the maximum over
#' variables of |statistic| / permutation SD (single-step max-T, which
#' accounts for multiplicity and for the correlation between variables).
#' @param S_list named list of per-chain sums (rows: chains of a, then b)
#' @param n_a number of chains in dataset a
#' @return list(per_var = tibble, global = tibble)
perm_test_moments <- function(S_list, n_a, n_t, n_perm) {
  n_all <- nrow(S_list[[1]])
  stat_all <- function(ia) {
    vapply(S_list, function(S) {
      two_sample_stats(S[ia, , drop = FALSE], S[-ia, , drop = FALSE], n_t)
    }, numeric(2))
  }
  obs <- stat_all(seq_len(n_a))
  null <- vapply(seq_len(n_perm), function(b) {
    stat_all(sample.int(n_all, n_a))
  }, obs)
  sd_null <- apply(null, c(1, 2), sd)
  p_var <- vapply(seq_len(ncol(obs)), function(j) {
    vapply(1:2, function(s) {
      (1 + sum(abs(null[s, j, ]) >= abs(obs[s, j]))) / (n_perm + 1)
    }, numeric(1))
  }, numeric(2))
  maxT <- function(x, s) max(abs(x[s, ]) / sd_null[s, ])
  global <- tibble::tibble(
    statistic = c("mean difference", "log variance ratio"),
    max_abs_z = c(maxT(obs, 1), maxT(obs, 2)),
    p_global = vapply(1:2, function(s) {
      (1 + sum(apply(null, 3, maxT, s = s) >= maxT(obs, s))) / (n_perm + 1)
    }, numeric(1))
  )
  per_var <- tibble::tibble(
    var = names(S_list),
    d_mean = obs[1, ], z_mean = obs[1, ] / sd_null[1, ], p_mean = p_var[1, ],
    log_vr = obs[2, ], z_var = obs[2, ] / sd_null[2, ], p_var = p_var[2, ]
  )
  list(per_var = per_var, global = global)
}

#' Two-sample energy statistic between chain groups, chain-permutation null
#'
#' Points are the whitened state vectors of every chain at a few
#' cross-sections. Whole chains are permuted, which keeps the dependence
#' between the cross-sections of a chain. All distances are summed once into
#' a chain x chain matrix G, so a permutation costs O(C^2). V-statistic, as
#' `energy_v()` (M2.4).
#' @param Z array [cross-section, chain, component], both groups
#' @param in_a logical, chain belongs to group a
#' @return list(stat, p, null)
energy_chain_test <- function(Z, in_a, n_perm) {
  n_s <- dim(Z)[1]
  n_c <- dim(Z)[2]
  P <- matrix(Z, n_s * n_c, dim(Z)[3])
  chain_of <- rep(seq_len(n_c), each = n_s)
  G <- matrix(0, n_c, n_c)
  for (i in seq_len(n_c)) {
    d <- pdist(P[chain_of == i, , drop = FALSE], P)
    G[i, ] <- rowsum(colSums(d), chain_of)[, 1]
  }
  stat <- function(a) {
    na <- sum(a) * n_s
    nb <- sum(!a) * n_s
    2 * sum(G[a, !a]) / (na * nb) - sum(G[a, a]) / na^2 -
      sum(G[!a, !a]) / nb^2
  }
  obs <- stat(in_a)
  null <- vapply(seq_len(n_perm), function(b) stat(sample(in_a)), numeric(1))
  list(stat = obs, p = (1 + sum(null >= obs)) / (n_perm + 1), null = null)
}

# Research windows after a cold-start burn-in (C3-M4) --------------------------------

#' Window functionals over years B + 1 ... B + L, for every chain and B
#' @return list of matrices [length(B_grid), n_chain]: M (mean), S2 (within
#'   variance, divisor L), slope (OLS slope per year)
window_funs <- function(y, L, B_grid) {
  x <- seq_len(L) - (L + 1) / 2
  res <- lapply(B_grid, function(B) {
    blk <- y[B + seq_len(L), , drop = FALSE]
    M <- colMeans(blk)
    list(M = M, S2 = colMeans(sweep(blk, 2, M)^2),
      slope = colSums(blk * x) / sum(x^2))
  })
  get <- function(nm) t(vapply(res, `[[`, numeric(ncol(y)), nm))
  list(M = get("M"), S2 = get("S2"), slope = get("slope"))
}

#' Stationary reference of the window functionals: every window starting
#' each year in [start, nrow(y) - L + 1], all chains, global mean (M2.7)
#' @return c(mu_M, var_M, S2, slope_sd)
window_ref_funs <- function(y, L, start) {
  w <- window_funs(y, L, seq(start, nrow(y) - L + 1) - 1)
  M <- as.vector(w$M)
  c(mu_M = mean(M), var_M = mean((M - mean(M))^2), S2 = mean(w$S2),
    slope_sd = sqrt(mean(w$slope^2)))
}

# Formatting --------------------------------------------------------------------------

#' "est [lo, hi]" with a fixed number of decimals
fmt_ci <- function(est, lo, hi, digits = 2) {
  f <- paste0("%.", digits, "f")
  sprintf(paste0(f, " [", f, ", ", f, "]"), est, lo, hi)
}
