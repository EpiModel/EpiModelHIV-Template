# =============================================================================
# 02_validate_methods.R
# Question : Do the estimators used in steps 03-07 recover known answers on
#            synthetic data of the same shape (254 chains x 600 years, all
#            chains restarted from one common state)?
# Inputs   : none (synthetic)
# Outputs  : results/tables/02_validation.csv
# Method   : METHODS.md M2; results/02_validate_methods.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
source("R/E-restart_assessment/00_config.R")
source("R/E-restart_assessment/utils.R")
set.seed(SEED)

n_c <- 254
n_y <- N_YEARS
B_VAL <- 200 # bootstrap replicates for the validation CIs

# Synthetic series ---------------------------------------------------------------

#' AR(1) with stationary variance `s2`, all chains started at `x0` (year 0)
ar1 <- function(a, s2 = 1, x0 = NULL) {
  sd_e <- sqrt(s2 * (1 - a^2))
  Y <- matrix(0, n_y, n_c)
  prev <- if (is.null(x0)) rnorm(n_c, 0, sqrt(s2)) else rep(x0, n_c)
  for (t in seq_len(n_y)) {
    prev <- a * prev + rnorm(n_c, 0, sd_e)
    Y[t, ] <- prev
  }
  Y
}

# S1: AR(1), a = 0.9, all chains restarted at x0 = 3 (an atypical state)
a1 <- 0.9
S1 <- ar1(a1, x0 = 3)
# S2: two AR(1) components (90% fast a = 0.5, 10% slow a = 0.98), both
#     restarted at 0 (a typical state); the slow component is hidden state
S2_fast <- ar1(0.5, 0.9, x0 = 0)
S2_slow <- ar1(0.98, 0.1, x0 = 0)
S2 <- S2_fast + S2_slow
# S3: stationary AR(1) plus a random walk (no stationary law). With the
#     brief's increment SD 0.02 the variance grows by 0.04 per century, i.e.
#     ~3.4% of v_pi, below VAR_DRIFT_TOL: flagging is then not guaranteed and
#     the check is only reported. S3b (SD 0.03, ~7.6% per century) is the
#     power check.
S3 <- ar1(a1) + apply(matrix(rnorm(n_y * n_c, 0, 0.02), n_y), 2, cumsum)
S3b <- ar1(a1) + apply(matrix(rnorm(n_y * n_c, 0, 0.03), n_y), 2, cumsum)
# S4: damped rotation, output u, hidden coordinate v
omega <- 2 * pi / 15
Rm <- 0.9 * matrix(c(cos(omega), sin(omega), -sin(omega), cos(omega)), 2)
S4u <- S4v <- matrix(0, n_y, n_c)
x <- matrix(rnorm(2 * n_c), 2)
for (t in seq_len(n_y)) {
  x <- Rm %*% x + matrix(rnorm(2 * n_c, 0, sqrt(0.19)), 2)
  S4u[t, ] <- x[1, ]
  S4v[t, ] <- x[2, ]
}

checks <- list()
# Criterion "in CI" is judged as |z| < 3 with z = (est - truth) / SE_boot and
# SE_boot = CI width / 3.92. A single realisation is checked against ~30
# truths, so a 95% CI would fail ~1.5 checks by chance alone; |z| < 3 is a
# Bonferroni-type correction for that (see 02_validate_methods.md). The
# coverage study at the end checks the CIs themselves over replications.
add_check <- function(check, truth, est, lo = NA, hi = NA, criterion) {
  z <- if (!is.na(lo)) (est - truth) / ((hi - lo) / 3.92) else NA_real_
  pass <- if (criterion == "in CI") {
    abs(z) < 3
  } else if (grepl("^rel", criterion)) {
    abs(est - truth) / abs(truth) <= as.numeric(sub("rel<", "", criterion))
  } else if (grepl("^abs", criterion)) {
    abs(est - truth) <= as.numeric(sub("abs<", "", criterion))
  } else if (criterion == "flagged") {
    isTRUE(est == 1)
  } else if (criterion == "not flagged") {
    isTRUE(est == 0)
  } else if (grepl("^range", criterion)) {
    r <- as.numeric(strsplit(sub("range ", "", criterion), "-")[[1]])
    est >= r[1] & est <= r[2]
  } else if (criterion == "report") {
    NA
  }
  checks[[length(checks) + 1]] <<- tibble(check, truth, est, lo, hi, z,
    criterion, pass)
}

eq <- EQ_START:n_y
pi_rows <- LATE_START:n_y

# Relaxation of the variance from a single restart point (M2.2, M2.5) ----------
# For AR(1) from a fixed x0: v(t) / v_pi = 1 - a^(2t), so ICC_x0(h) = a^(2h)
# and the variance time constant is -1 / (2 log a).
boot_icc <- function(Y, h) {
  bm <- chain_boot(n_c, B_VAL, function(i) {
    y <- Y[, i]
    1 - cross_moments(y)$v[h] / pi_moments(y, pi_rows)$s2
  })
  est <- 1 - cross_moments(Y)$v[h] / pi_moments(Y, pi_rows)$s2
  c(est, quantile(bm, c(0.025, 0.975)))
}
for (h in c(5, 10, 20)) {
  r <- boot_icc(S1, h)
  add_check(paste0("S1 ICC_x0(", h, ") = 1 - v(h)/v_pi"), a1^(2 * h),
    r[1], r[2], r[3], "in CI")
}
relax_tau <- function(Y) {
  fit_var_relax(1:LATE_START,
    cross_moments(Y)$v[1:LATE_START] / pi_moments(Y, pi_rows)$s2)$coef[2]
}
bm <- chain_boot(n_c, B_VAL, function(i) relax_tau(S1[, i]))
add_check("S1 variance relaxation tau (fit)", -1 / (2 * log(a1)),
  relax_tau(S1), quantile(bm, 0.025), quantile(bm, 0.975), "in CI")
for (h in c(10, 30)) {
  r <- boot_icc(S2, h)
  add_check(paste0("S2 ICC_x0(", h, ") = 1 - v(h)/v_pi"),
    0.9 * 0.25^h + 0.1 * 0.98^(2 * h), r[1], r[2], r[3], "in CI")
}
# mean relaxation: m(t) = 3 a^t
add_check("S1 mean at year 10", 3 * a1^10, mean(S1[10, ]),
  mean(S1[10, ]) - 1.96 * sd(S1[10, ]) / sqrt(n_c),
  mean(S1[10, ]) + 1.96 * sd(S1[10, ]) / sqrt(n_c), "in CI")

# Pooled ACF and tau_int (M2.6) --------------------------------------------------
acf_boot <- function(Y, lags, max_lag) {
  est <- pooled_acf(Y[eq, ], max_lag)
  bm <- chain_boot(n_c, B_VAL, function(i) {
    r <- pooled_acf(Y[eq, i], max_lag)
    c(r[lags + 1], tau_geyer(r)$tau)
  })
  list(est = c(est[lags + 1], tau_geyer(est)$tau), ci = boot_ci(bm))
}
lags <- c(1, 5, 10, 20)
r <- acf_boot(S1, lags, ACF_MAX_LAG)
for (j in seq_along(lags)) {
  add_check(paste0("S1 rho(", lags[j], ")"), a1^lags[j], r$est[j],
    r$ci[j, 1], r$ci[j, 2], "in CI")
}
add_check("S1 tau_int (Geyer)", (1 + a1) / (1 - a1), r$est[5],
  r$ci[5, 1], r$ci[5, 2], "in CI")
r <- acf_boot(S2, c(1, 10, 50), ACF_MAX_LAG)
tr <- function(k) 0.9 * 0.5^k + 0.1 * 0.98^k
for (j in 1:3) {
  k <- c(1, 10, 50)[j]
  add_check(paste0("S2 rho(", k, ")"), tr(k), r$est[j], r$ci[j, 1],
    r$ci[j, 2], "in CI")
}
add_check("S2 tau_int (Geyer)", 0.9 * 3 + 0.1 * 99, r$est[4],
  r$ci[4, 1], r$ci[4, 2], "in CI")
# The FFT-based ACF used in step 05 must equal the direct computation
add_check("Fast pooled ACF == direct pooled ACF (max abs diff)", 0,
  max(abs(acf_from_parts(acf_parts(S2[eq, ], ACF_MAX_LAG)) -
    pooled_acf(S2[eq, ], ACF_MAX_LAG))), criterion = "abs<1e-10")
r <- acf_boot(S4u, c(5, 10), 60)
add_check("S4 rho_u(5)", 0.9^5 * cos(5 * omega), r$est[1], r$ci[1, 1],
  r$ci[1, 2], "in CI")

# Window decomposition and variance-time curve (M2.7) --------------------------
ws <- window_split(S1, WINDOW_L, EQ_START)
add_check("Window identity |within + between - total|", 0,
  abs(ws["within"] + ws["between"] - ws["total"]), criterion = "abs<1e-10")
exact_vm <- function(a, L) {
  k <- 1:(L - 1)
  (L + 2 * sum((L - k) * a^k)) / L^2
}
bm <- chain_boot(n_c, B_VAL, function(i) {
  w <- window_split(S1[, i], WINDOW_L, EQ_START)
  w["between"] / w["total"]
})
add_check("S1 Var(M_20) / Var_pi", exact_vm(a1, 20),
  ws["between"] / ws["total"], quantile(bm, 0.025), quantile(bm, 0.975),
  "in CI")
bm <- chain_boot(n_c, B_VAL, function(i) {
  variance_time(S1[, i], 100, EQ_START)
})
add_check("S1 L Var(M_L)/Var_pi at L = 100", 100 * exact_vm(a1, 100),
  variance_time(S1, 100, EQ_START), quantile(bm, 0.025),
  quantile(bm, 0.975), "in CI")

# Drift tests (M2.2) -------------------------------------------------------------
drift_flag <- function(Y) {
  yrs <- DRIFT_PERIODS[[1]][1]:DRIFT_PERIODS[[1]][2]
  est <- drift_stats(Y, yrs)
  bm <- chain_boot(n_c, B_VAL, function(i) drift_stats(Y[, i], yrs))
  ci <- boot_ci(bm)
  flag_v <- (ci[2, 1] > 0 | ci[2, 2] < 0) & abs(est[2]) > VAR_DRIFT_TOL
  flag_m <- (ci[1, 1] > 0 | ci[1, 2] < 0) & abs(est[1]) > MEAN_DRIFT_TOL
  as.numeric(flag_v | flag_m)
}
add_check("S1 drift test (stationary)", 0, drift_flag(S1),
  criterion = "not flagged")
add_check("S3 drift test (random walk, SD 0.02: below tolerance)", NA,
  drift_flag(S3), criterion = "report")
add_check("S3b drift test (random walk, SD 0.03: above tolerance)", 1,
  drift_flag(S3b), criterion = "flagged")

# Time to stationarity: detection rules on the energy distance (M2.5) ----------
# The brief's rule (first year after which D exceeds the null q95 in <= 5% of
# years with runs <= 3) and a null-maximum variant are applied to S1. The true
# convergence is fast (variance within 5% at t ~ 14, mean within 0.1 SD at
# t ~ 32). Both rules are also applied to a fully stationary AR(1) (S0),
# where the right answer is t ~ 1.
S0 <- ar1(a1)
t_rules <- function(Y, lab) {
  z <- (Y - pi_moments(Y, pi_rows)$mu) / sqrt(pi_moments(Y, pi_rows)$s2)
  D <- rowMeans(energy_trajectory(array(z, c(n_y, n_c, 1)), 1:n_y,
    REF_YEARS, 10))
  q <- quantile(D[LATE_START:n_y], T_Q)
  add_check(paste0(lab, " T by the brief's rule (q95, runs <= 3)"), NA,
    t_rule(D, 1:n_y, q, LATE_START, T_Q, T_MAX_RUN), criterion = "report")
  add_check(paste0(lab, " T by the null-maximum rule"), NA,
    t_full_rule(D, LATE_START, SMOOTH_W, "max")$t, criterion = "report")
}
t_rules(S1, "S1")
t_rules(S0, "S0 (stationary start)")

# Time to stationarity: tolerance on fitted relaxation curves (M2.5) -----------
# T_var(eps): fitted 1 - v(t)/v_pi stays below eps. T_mean(delta): fitted
# |m(t) - mu| / SD stays below delta. CIs by refitting on chain bootstraps.
t_fits <- function(Y, eps, delta) {
  pm <- pi_moments(Y, pi_rows)
  cm <- cross_moments(Y[1:LATE_START, , drop = FALSE])
  fv <- fit_var_relax(1:LATE_START, cm$v / pm$s2)
  fm <- fit_mean_relax(1:LATE_START, (cm$m - pm$mu) / sqrt(pm$s2))
  c(
    t_var = t_from_fit(function(t) 1 - fv$fn(t), eps),
    t_mean = t_from_fit(fm$fn, delta)
  )
}
tf_check <- function(Y, lab, eps, delta, truth_v, truth_m) {
  est <- t_fits(Y, eps, delta)
  bm <- chain_boot(n_c, B_VAL, function(i) t_fits(Y[, i], eps, delta))
  ci <- boot_ci(bm)
  add_check(paste0(lab, " T_var(", eps, ") from fit"), truth_v, est[1],
    ci[1, 1], ci[1, 2], "in CI")
  if (!is.na(truth_m)) {
    add_check(paste0(lab, " T_mean(", delta, " SD) from fit"), truth_m,
      est[2], ci[2, 1], ci[2, 2], "in CI")
  }
}
tf_check(S1, "S1", 0.05, 0.1, log(0.05) / (2 * log(a1)), log(0.1 / 3) /
  log(a1))
tf_check(S1, "S1", 0.10, 0.2, log(0.10) / (2 * log(a1)), log(0.2 / 3) /
  log(a1))
s2_def <- function(t) 0.9 * 0.25^t + 0.1 * 0.98^(2 * t)
tf_check(S2, "S2", 0.05, 0.1,
  uniroot(function(t) s2_def(t) - 0.05, c(0, 500))$root, NA)

# Restart-memory lower bounds with pseudo-restarts (M2.3) ------------------------
t0s <- seq(EQ_START + max(FEATURE_LAGS), n_y - 30, PSEUDO_RESTART_STEP)
rows <- restart_rows(t0s, n_c)
bound <- function(Ylist, feat_vars, lags, target, hs) {
  X <- restart_features(Ylist, feat_vars, rows, lags)
  Yr <- sapply(hs, function(h) restart_value(target, rows, h))
  pred <- ridge_cv(X, Yr, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
  t(sapply(seq_along(hs), function(j) {
    r2_boot(Yr[, j], pred[, j], mean(Yr[, j]), rows$chain, B_VAL)
  }))
}
r <- bound(list(u = S1), "u", integer(0), S1, c(5, 10))
add_check("S1 R2 bound own value, h = 5", a1^10, r[1, 1], r[1, 2], r[1, 3],
  "in CI")
add_check("S1 R2 bound own value, h = 10", a1^20, r[2, 1], r[2, 2], r[2, 3],
  "in CI")
r <- bound(list(f = S2_fast, s = S2_slow), c("f", "s"), integer(0), S2,
  c(10, 30))
add_check("S2 R2 bound full state, h = 10", 0.9 * 0.25^10 + 0.1 * 0.98^20,
  r[1, 1], r[1, 2], r[1, 3], "in CI")
add_check("S2 R2 bound full state, h = 30", 0.1 * 0.98^60,
  r[2, 1], r[2, 2], r[2, 3], "in CI")
r <- bound(list(y = S2), "y", integer(0), S2, 10)
add_check("S2 R2 bound own value, h = 10 (= rho(10)^2)", tr(10)^2,
  r[1, 1], r[1, 2], r[1, 3], "in CI")
r <- bound(list(y = S2), "y", c(1, 2, 5), S2, 10)
add_check("S2 R2 bound own value + lags, h = 10 (between rho^2 and ICC)",
  NA, r[1, 1], r[1, 2], r[1, 3],
  paste0("range ", signif(tr(10)^2, 3), "-",
    signif(0.9 * 0.25^10 + 0.1 * 0.98^20, 3)))
r <- bound(list(u = S4u, v = S4v), c("u", "v"), integer(0), S4u, 5)
add_check("S4 R2 bound state (u, v), h = 5", 0.81^5, r[1, 1], r[1, 2],
  r[1, 3], "in CI")
r <- bound(list(u = S4u), "u", integer(0), S4u, 5)
add_check("S4 R2 bound u only, h = 5 (= rho_u(5)^2)",
  (0.9^5 * cos(5 * omega))^2, r[1, 1], r[1, 2], r[1, 3], "in CI")

# Coverage study over replications ---------------------------------------------
# Re-simulate S1 R_COV times and record how often the 95% chain-bootstrap CIs
# of the two central estimators (ICC_x0(h) = 1 - v(h)/v_pi and rho(k)) cover
# the truth. Nominal: 0.95.
R_COV <- 100
cov <- t(replicate(R_COV, {
  Y <- ar1(a1, x0 = 3)
  r1 <- boot_icc(Y, 10)
  est <- pooled_acf(Y[eq, ], 10)[11]
  bm <- chain_boot(n_c, B_VAL, function(i) pooled_acf(Y[eq, i], 10)[11])
  c(icc = r1[1], icc_cov = a1^20 >= r1[2] & a1^20 <= r1[3],
    rho = est, rho_cov = a1^10 >= quantile(bm, 0.025) &
      a1^10 <= quantile(bm, 0.975))
}))
add_check("Coverage of 95% CI, S1 ICC_x0(10) (100 replications)", 0.95,
  mean(cov[, 2]), criterion = "range 0.89-1")
add_check("Mean of S1 ICC_x0(10) estimates (100 replications)", a1^20,
  mean(cov[, 1]), mean(cov[, 1]) - 1.96 * sd(cov[, 1]) / sqrt(R_COV),
  mean(cov[, 1]) + 1.96 * sd(cov[, 1]) / sqrt(R_COV), "in CI")
add_check("Coverage of 95% CI, S1 rho(10) (100 replications)", 0.95,
  mean(cov[, 4]), criterion = "range 0.89-1")
add_check("Mean of S1 rho(10) estimates (100 replications)", a1^10,
  mean(cov[, 3]), mean(cov[, 3]) - 1.96 * sd(cov[, 3]) / sqrt(R_COV),
  mean(cov[, 3]) + 1.96 * sd(cov[, 3]) / sqrt(R_COV), "in CI")

# Output -------------------------------------------------------------------------
val <- bind_rows(checks)
write_tab(val, "02_validation.csv")
print(as.data.frame(val))
cat("\nAll checks passed:", all(val$pass, na.rm = TRUE), "\n")
save_session("02")
