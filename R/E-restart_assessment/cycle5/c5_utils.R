## Shared functions for cycle 5
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle5/`, after `c5_config.R` (which loads the
## functions of cycles 1-4). Section numbers (C5-Mx) refer to
## `R/E-restart_assessment/cycle5/results/c5_METHODS.md`.

# Annual data (C5-M1) ----------------------------------------------------------------

#' Annual matrices of one merged scenario tibble
#'
#' Keeps steps 2 ... n_years * 52 + 1 (year k = steps (k - 1) * 52 + 2 ...
#' k * 52 + 1, as cycle 4), checks that every run has all of them and that
#' the copied restart state (step 2) is the pool point `sim_number`.
#' @param d merged tibble; pool_epi [point, variable] saved states
#' @return list(Y, point, sim) with Y the dictionary variables [year, run]
annual_scenario <- function(d, n_years, pool_epi, dict, kind) {
  steps <- restart_time + seq_len(n_years * year_steps) - 1
  d <- d[d$time %in% steps, ]
  d <- d[order(d$sim, d$time), ]
  sims <- sort(unique(d$sim))
  stopifnot(all(table(d$sim) == length(steps)))
  raw_vars <- names(kind)
  stopifnot(all(raw_vars %in% names(d)), !anyNA(d[raw_vars]))
  first <- d[d$time == restart_time, ]
  common <- intersect(raw_vars, colnames(pool_epi))
  P <- t(pool_epi[, common, drop = FALSE])
  point <- vapply(seq_len(nrow(first)), function(i) {
    hit <- which(colSums(abs(P - unlist(first[i, common]))) == 0)
    if (length(hit) == 1) hit else NA_integer_
  }, integer(1))
  stopifnot(!anyNA(point), all(point == first$sim_number))
  A <- setNames(lapply(raw_vars, function(v) {
    annualise(d[[v]], kind[[v]], n_years, length(sims))
  }), raw_vars)
  Y <- add_project_vars_c3(c(derive_vars(A), A))
  list(Y = Y[dict$name], point = point, sim = sims)
}

# Paired effects and effect heterogeneity (C5-M2) -------------------------------------------

#' Point-level summary of one outcome in two arms
#'
#' @param ya,y0 outcome of each run in the scenario arm a and the reference
#'   arm 0; ga,g0 their restart points (the same set of k points)
#' @return list(ma, m0, na, n0, swa, sw0, dfa, df0): point means, runs per
#'   point, pooled within-point variances and their degrees of freedom
point_summary <- function(ya, ga, y0, g0) {
  pts <- sort(unique(g0))
  stopifnot(setequal(unique(ga), pts))
  na <- tabulate(match(ga, pts), length(pts))
  n0 <- tabulate(match(g0, pts), length(pts))
  ma <- as.vector(tapply(ya, factor(ga, pts), mean))
  m0 <- as.vector(tapply(y0, factor(g0, pts), mean))
  wa <- sum((ya - ma[match(ga, pts)])^2)
  w0 <- sum((y0 - m0[match(g0, pts)])^2)
  dfa <- length(ya) - length(pts)
  df0 <- length(y0) - length(pts)
  list(ma = ma, m0 = m0, na = na, n0 = n0, swa = wa / dfa, sw0 = w0 / df0,
    dfa = dfa, df0 = df0)
}

#' Paired effect, its SE and the effect heterogeneity (C5-M2)
#'
#' Each point j gives a within-point difference d_j = ma_j - m0_j. With the
#' points drawn from pi, every point has the same weight:
#'   delta    = mean(d_j), the pi-average effect;
#'   se       = sd(d_j) / sqrt(k), which contains chance and heterogeneity;
#'   noise    = mean_j(swa / na_j + sw0 / n0_j), the part of var(d_j) due to
#'              chance after the restart;
#'   s2_delta = var(d_j) - noise, the ANOVA estimate of the variance of the
#'              conditional effect Delta(x) between points (can be < 0);
#'   F        = var(d_j) / noise, compared with F(k - 1, dfa + df0) under no
#'              heterogeneity (exact for a balanced design and normal runs);
#'   s2_lo, s2_hi: 95% CI of s2_delta by inverting that F ratio.
#' Relative quantities use the reference mean mu0 = mean(m0_j):
#'   pia = -delta / mu0 (for incidence counts: share of infections averted);
#'   sigma_e = sqrt(max(s2_delta, 0)) / mu0 (in PIA units).
#' The effect ICC is s2_delta / (s2_delta + swa + sw0) (SCENARIOS.md 3.2).
#' @return one-row tibble
paired_effect <- function(ps) {
  d <- ps$ma - ps$m0
  k <- length(d)
  mu0 <- mean(ps$m0)
  noise <- mean(ps$swa / ps$na + ps$sw0 / ps$n0)
  vd <- var(d)
  df_w <- ps$dfa + ps$df0
  Fr <- vd / noise
  q <- qf(c(0.975, 0.025), k - 1, df_w)
  s2 <- vd - noise
  s2_lo <- noise * (Fr / q[1] - 1)
  s2_hi <- noise * (Fr / q[2] - 1)
  tq <- qt(0.975, k - 1)
  delta <- mean(d)
  se <- sqrt(vd / k)
  tibble::tibble(
    k = k, mu0 = mu0, delta = delta, se = se,
    delta_lo = delta - tq * se, delta_hi = delta + tq * se,
    pia = -delta / mu0, pia_se = se / mu0,
    swa = ps$swa, sw0 = ps$sw0, noise = noise, var_d = vd,
    s2_delta = s2, s2_lo = s2_lo, s2_hi = s2_hi,
    F = Fr, p_het = pf(Fr, k - 1, df_w, lower.tail = FALSE),
    sigma_e = sqrt(max(s2, 0)) / mu0,
    sigma_e_lo = sqrt(max(s2_lo, 0)) / mu0,
    sigma_e_hi = sqrt(max(s2_hi, 0)) / mu0,
    icc_delta = max(s2, 0) / (max(s2, 0) + ps$swa + ps$sw0)
  )
}

#' Level ICC of the reference arm from its own point structure (ANOVA)
#' and, when a pi variance is given, the `icc_w` of cycle 4 (C4-M2)
level_icc <- function(y0, g0, v_pi = NA) {
  a <- nested_anova(matrix(y0, nrow = 1), g0)
  c(sb2 = a$sb2, sw2 = a$sw2, icc_a = a$sb2 / (a$sb2 + a$sw2),
    icc_w = 1 - a$sw2 / v_pi)
}

#' Error of the estimated effect under the designs of SCENARIOS.md 4.2
#'
#' Variance of the estimated effect against the pi-average effect, for N
#' runs per scenario, from the between-point variance sb2 of the reference
#' level, the within-point variance sw2 (average of the two arms) and the
#' effect heterogeneity s2d:
#'   paired, k points used equally often: s2d / k + 2 sw2 / N;
#'   unpaired, points drawn at random with replacement from k:
#'     2 sb2 S + s2d S + 2 sw2 / N, with S = E[sum n_j^2] / N^2
#'     = (1 + (N - 1) / k) / N;
#'   unpaired, independent points: 2 (sb2 + sw2) / N + s2d / N.
#' @return named vector of RMSEs (same units as the outcome)
design_rmse <- function(sb2, sw2, s2d, N = 32) {
  s2d <- max(s2d, 0)
  S <- function(k) (1 + (N - 1) / k) / N
  sqrt(c(
    paired_1 = s2d + 2 * sw2 / N,
    paired_8 = s2d / 8 + 2 * sw2 / N,
    paired_32 = s2d / 32 + 2 * sw2 / N,
    random_32 = 2 * sb2 * S(32) + s2d * S(32) + 2 * sw2 / N,
    independent = 2 * (sb2 + sw2) / N + s2d / N
  ))
}

#' Bootstrap over restart points of a paired-effect statistic
#'
#' Points are drawn with replacement and keep all their runs in both arms.
#' @param fun function(ps) -> named numeric vector
point_boot_paired <- function(ya, ga, y0, g0, fun, B) {
  pts <- sort(unique(g0))
  ia <- split(seq_along(ga), factor(ga, pts))
  i0 <- split(seq_along(g0), factor(g0, pts))
  t(vapply(seq_len(B), function(b) {
    draw <- sample(length(pts), replace = TRUE)
    ra <- unlist(ia[draw])
    r0 <- unlist(i0[draw])
    na <- lengths(ia[draw])
    n0 <- lengths(i0[draw])
    ps <- point_summary(ya[ra], rep(seq_along(draw), na),
      y0[r0], rep(seq_along(draw), n0))
    fun(ps)
  }, numeric(length(fun(point_summary(ya, ga, y0, g0))))))
}

# Outcomes of the short runs (C5-M1) --------------------------------------------------------

#' Per-run outcomes of the short runs (years 6-15 = the intervention period)
#'
#' @param a annual object of one arm (`annual_scenario`)
#' @return tibble, one row per run
short_outcomes <- function(a) {
  yrs <- (INT_B + 1):(INT_B + INT_L)
  Y <- a$Y
  cs <- function(v) colSums(Y[[v]][yrs, , drop = FALSE])
  last <- function(v) Y[[v]][INT_B + INT_L, ]
  tibble::tibble(
    point = a$point,
    cml_incid = cs("hiv.incid"),
    cml_incid.B = cs("hiv.incid.B"),
    cml_incid.H = cs("hiv.incid.H"),
    cml_incid.W = cs("hiv.incid.W"),
    cml_gono = cs("gono.incid"),
    cml_chla = cs("chla.incid"),
    cml_syph = cs("syph.incid"),
    prev_y15 = last("prev"),
    incid_rate_y15 = last("incid_rate"),
    dx_frac_y15 = last("dx_frac"),
    prep_cov_y15 = last("prep_cov")
  )
}
