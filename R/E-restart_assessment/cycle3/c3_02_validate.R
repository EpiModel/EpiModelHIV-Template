# =============================================================================
# c3_02_validate.R
# Question : Do the cycle 3 estimators recover known answers on synthetic
#            cold-start data of the same shape (256 chains x 600 years)?
#              - tolerance times T_mean(delta), T_var(eps) and the residual
#                bias o(70) after a cold start, including an HIV-like
#                overshoot and an over-dispersed start;
#              - the same-law tests (chain permutation) under H0 and H1.
# Inputs   : none (synthetic)
# Outputs  : cycle3/results/tables/c3_02_validation.csv
# Method   : c3_METHODS.md C3-M2, C3-M3, C3-M4; results/c3_02_validate.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

n_c <- 256
n_y <- N_YEARS
B_VAL <- 200 # bootstrap replicates for the validation CIs
fit_t <- FIT_START:LATE_START
pi_rows <- LATE_START:n_y

# Synthetic series ---------------------------------------------------------------
# Sums of AR(1) components with stationary variances v (sum 1). All chains
# start either at a common state x0 (one value per component) or from
# independent draws N(m0, s0^2). Truths, with Sigma v = 1:
#   o(t) = sum_k x0_k a_k^t          (or m0_k)
#   r(t) = 1 + sum_k (s0_k^2 - v_k) a_k^(2t)
ar_mix <- function(a, v, x0 = NULL, m0 = NULL, s0 = NULL, n_chain = n_c,
                   n_year = n_y) {
  Y <- matrix(0, n_year, n_chain)
  for (k in seq_along(a)) {
    sd_e <- sqrt(v[k] * (1 - a[k]^2))
    x <- if (!is.null(x0)) {
      rep(x0[k], n_chain)
    } else if (!is.null(m0)) {
      rnorm(n_chain, m0[k], s0[k])
    } else {
      rnorm(n_chain, 0, sqrt(v[k]))
    }
    for (t in seq_len(n_year)) {
      x <- a[k] * x + rnorm(n_chain, 0, sd_e)
      Y[t, ] <- Y[t, ] + x
    }
  }
  Y
}
truth_o <- function(a, start) function(t) {
  out <- 0
  for (k in seq_along(a)) out <- out + start[k] * a[k]^t
  out
}
truth_r <- function(a, v, s0 = rep(0, length(a))) function(t) {
  out <- 1
  for (k in seq_along(a)) out <- out + (s0[k]^2 - v[k]) * a[k]^(2 * t)
  out
}

# C0: stationary AR(1), a = 0.9 (no transient)
C0 <- ar_mix(0.9, 1)
# C1: the brief's S1, AR(1) a = 0.9, every chain started at 5
C1 <- ar_mix(0.9, 1, x0 = 5)
# C2: over-dispersed random start, AR(1) a = 0.95, x_0 ~ N(-3, 2^2):
#     r(t) > 1 early
C2 <- ar_mix(0.95, 1, m0 = -3, s0 = 2)
# C3: HIV-like overshoot. Slow component (tau = 17.5 y, 80% of the variance)
#     started at +64 SD and fast one (tau = 8 y) at -95 SD: the offset starts
#     negative, peaks at ~+12.6 SD near year 20 and decays with tau = 17.5 y,
#     as HIV prevalence after the cold start (c3_01).
a3 <- exp(-1 / c(17.5, 8))
v3 <- c(0.8, 0.2)
x3 <- c(64, -95)
C3 <- ar_mix(a3, v3, x0 = x3)

series <- list(
  C1 = list(Y = C1, o = truth_o(0.9, 5), r = truth_r(0.9, 1)),
  C2 = list(Y = C2, o = truth_o(0.95, -3), r = truth_r(0.95, 1, 2)),
  C3 = list(Y = C3, o = truth_o(a3, x3), r = truth_r(a3, v3))
)

checks <- list()
# Criterion as cycle 1 (02_validate_methods.R): |z| < 3 with
# z = (estimate - truth) / SE_boot, SE_boot = CI width / 3.92.
add_check <- function(check, truth, est, lo = NA, hi = NA, criterion) {
  z <- if (!is.na(lo)) (est - truth) / ((hi - lo) / 3.92) else NA_real_
  pass <- if (criterion == "in CI") {
    abs(z) < 3
  } else if (grepl("^range", criterion)) {
    r <- as.numeric(strsplit(sub("range ", "", criterion), " to ")[[1]])
    est >= r[1] & est <= r[2]
  } else if (criterion == "report") {
    NA
  }
  checks[[length(checks) + 1]] <<- tibble(check, truth, est, lo, hi, z,
    criterion, pass)
}

# Tolerance times and residual bias (C3-M3, C3-M4) ------------------------------
# T for a known curve uses the same definition as for a fitted one.
d_mcse <- MCSE_FRAC / sqrt(256)
times_vec <- function(Y, tail_level = TAIL_LEVEL) {
  ct <- cold_times(Y, fit_t, pi_rows, c(0.1, 0.2), c(0.1, 0.2, d_mcse),
    at = PROD_BURNIN, tail_level = tail_level)
  c(ct$t_var, ct$t_mean, ct$o_fit, ct$t_tail)
}
nm <- c("T_var(0.1)", "T_var(0.2)", "T_mean(0.1)", "T_mean(0.2)",
  paste0("T_mean(", signif(d_mcse, 2), " = 0.2 MCSE, N = 256)"),
  "fitted o(70)", "tail window start")
for (s in names(series)) {
  S <- series[[s]]
  tr <- c(
    vapply(c(0.1, 0.2), function(e) t_from_fit(function(t) 1 - S$r(t), e),
      numeric(1)),
    vapply(c(0.1, 0.2, d_mcse), function(d) t_from_fit(S$o, d), numeric(1)),
    S$o(PROD_BURNIN), NA
  )
  est <- times_vec(S$Y)
  ci <- boot_ci(do.call(rbind, parallel::mclapply(seq_len(B_VAL),
    mc.cores = N_CORES, function(b) {
      times_vec(S$Y[, sample.int(n_c, n_c, replace = TRUE)])
    })))
  for (j in seq_along(nm)) {
    if (j == 5 && s != "C3") next # MCSE time: overshoot series only
    add_check(paste(s, nm[j]), tr[j], est[j], ci[j, 1], ci[j, 2],
      if (j == length(nm)) "report" else "in CI")
  }
  # empirical residual bias at year 70 (the production burn-in)
  y70 <- S$Y[PROD_BURNIN, ]
  pm <- pi_moments(S$Y, pi_rows)
  e70 <- (mean(y70) - pm$mu) / sqrt(pm$s2)
  bm <- chain_boot(n_c, B_VAL, function(i) {
    p <- pi_moments(S$Y[, i], pi_rows)
    (mean(S$Y[PROD_BURNIN, i]) - p$mu) / sqrt(p$s2)
  })
  add_check(paste(s, "empirical o(70)"), S$o(PROD_BURNIN), e70,
    quantile(bm, 0.025), quantile(bm, 0.975), "in CI")
}
# Without the tail window (cycle 1 practice: fit from FIT_START), for C3
est_nt <- times_vec(C3, tail_level = Inf)
add_check("C3 T_mean(0.1), fit from FIT_START (no tail window)",
  t_from_fit(series$C3$o, 0.1), est_nt[3], criterion = "report")
add_check("C3 fitted o(70), fit from FIT_START (no tail window)",
  series$C3$o(PROD_BURNIN), est_nt[6], criterion = "report")

# No transient: stationary start (C0)
est0 <- times_vec(C0)
add_check("C0 (stationary) T_mean(0.1)", 0, est0[3], criterion = "range 0 to 10")
add_check("C0 (stationary) T_var(0.1)", 0, est0[1], criterion = "range 0 to 10")

# Research windows after a burn-in B (C3-M4) ---------------------------------------
# Offset of the 20-year window mean in SD_pi(M_20) units, C3, B = 50, 100.
# Truth: mean of o(t) over the window / SD(M_20), with
# Var(M_L) = sum_k v_k (L + 2 sum_j (L - j) a_k^j) / L^2.
L <- WINDOW_L
var_M <- sum(vapply(seq_along(a3), function(k) {
  j <- 1:(L - 1)
  v3[k] * (L + 2 * sum((L - j) * a3[k]^j)) / L^2
}, numeric(1)))
w_off <- function(Y, B) {
  ref <- window_ref_funs(Y, L, LATE_START)
  (mean(window_funs(Y, L, B)$M) - ref["mu_M"]) / sqrt(ref["var_M"])
}
for (B in c(50, 100)) {
  tru <- mean(series$C3$o(B + seq_len(L))) / sqrt(var_M)
  bm <- chain_boot(n_c, B_VAL, function(i) w_off(C3[, i], B))
  add_check(paste0("C3 20-year window-mean offset, B = ", B), tru,
    w_off(C3, B), quantile(bm, 0.025), quantile(bm, 0.975), "in CI")
}

# Coverage of the bootstrap CIs over replications (C3) ------------------------------
# 30 new C3 datasets, 100 bootstrap refits each: how often the 95% CIs of
# T_mean(0.1) and of the empirical o(70) cover the truth.
R_COV <- 30
t_true <- t_from_fit(series$C3$o, 0.1)
o_true <- series$C3$o(PROD_BURNIN)
cov <- do.call(rbind, parallel::mclapply(seq_len(R_COV), mc.cores = N_CORES,
  function(r) {
    Y <- ar_mix(a3, v3, x0 = x3)
    f <- function(i) {
      y <- Y[, i]
      p <- pi_moments(y, pi_rows)
      ct <- cold_times(y, fit_t, pi_rows, 0.1, 0.1)
      c(ct$t_mean, (mean(y[PROD_BURNIN, ]) - p$mu) / sqrt(p$s2))
    }
    est <- f(seq_len(n_c))
    bm <- do.call(rbind, lapply(1:100, function(b) {
      f(sample.int(n_c, n_c, replace = TRUE))
    }))
    ci <- boot_ci(bm)
    c(est, t_true >= ci[1, 1] & t_true <= ci[1, 2],
      o_true >= ci[2, 1] & o_true <= ci[2, 2])
  }))
add_check("C3 T_mean(0.1): mean over 30 replications", t_true, mean(cov[, 1]),
  mean(cov[, 1]) - 1.96 * sd(cov[, 1]) / sqrt(R_COV),
  mean(cov[, 1]) + 1.96 * sd(cov[, 1]) / sqrt(R_COV), "in CI")
add_check("C3 T_mean(0.1): coverage of the 95% CI (30 replications)", 0.95,
  mean(cov[, 3]), criterion = "report")
add_check("C3 empirical o(70): coverage of the 95% CI (30 replications)", 0.95,
  mean(cov[, 4]), criterion = "range 0.83 to 1")

# Same-law tests (C3-M2) ------------------------------------------------------------
# Two datasets of 256 and 254 chains, stationary, 301 reference years, six
# variables: three AR(1) (a = 0.5, 0.9, 0.98) and three mixtures of them, so
# the variables are correlated. Under H0 both come from the same law; under
# H1 variable 2 (a = 0.9) of dataset b is shifted by `shift` SD, or its
# variance scaled by `vscale`.
n_ref <- LATE_START
make_set <- function(n_chain, shift = 0, vscale = 1) {
  u <- lapply(c(0.5, 0.9, 0.98), function(a) {
    ar_mix(a, 1, n_chain = n_chain, n_year = n_ref + 1)
  })
  Y <- list(u[[1]], u[[2]], u[[3]], (u[[1]] + u[[2]]) / sqrt(2),
    (u[[2]] + u[[3]]) / sqrt(2), (u[[1]] + u[[3]]) / sqrt(2))
  Y[[2]] <- sqrt(vscale) * Y[[2]] + shift
  setNames(Y, paste0("v", 1:6))
}
perm_once <- function(shift = 0, vscale = 1, n_perm = 500) {
  A <- make_set(256)
  B <- make_set(254, shift, vscale)
  rows <- seq_len(n_ref + 1)
  S <- lapply(names(A), function(v) {
    rbind(chain_sums(A[[v]], rows), chain_sums(B[[v]], rows))
  })
  names(S) <- names(A)
  pt <- perm_test_moments(S, 256, length(rows), n_perm)
  pt$global$p_global
}
sim_rates <- function(n_rep, ...) {
  p <- do.call(rbind, parallel::mclapply(seq_len(n_rep), mc.cores = N_CORES,
    function(r) perm_once(...)))
  colMeans(p <= 0.05)
}
h0 <- sim_rates(200)
add_check("Same-law test, H0: rejection rate, means (200 reps, 5% level)",
  0.05, h0[1], criterion = "range 0.02 to 0.085")
add_check("Same-law test, H0: rejection rate, variances (200 reps)", 0.05,
  h0[2], criterion = "range 0.02 to 0.085")
h1 <- sim_rates(100, shift = 0.1)
add_check("Same-law test, H1 mean shift 0.1 SD (a = 0.9): power, means",
  NA, h1[1], criterion = "range 0.8 to 1")
h1v <- sim_rates(100, vscale = 1.1)
add_check("Same-law test, H1 variance x1.1 (a = 0.9): power, variances",
  NA, h1v[2], criterion = "report")

# Energy test with chain blocks: H0 rejection rate on whitened data
energy_once <- function(shift = 0) {
  A <- make_set(256)
  B <- make_set(254, shift)
  yrs <- seq(1, n_ref + 1, by = ED_YEAR_STEP)
  Z <- simplify2array(lapply(names(A), function(v) {
    cbind(A[[v]][yrs, ], B[[v]][yrs, ])
  }))
  energy_chain_test(Z, rep(c(TRUE, FALSE), c(256, 254)), 200)$p
}
e0 <- unlist(parallel::mclapply(1:100, mc.cores = N_CORES,
  function(r) energy_once()))
add_check("Energy chain test, H0: rejection rate (100 reps)", 0.05,
  mean(e0 <= 0.05), criterion = "range 0.01 to 0.11")
e1 <- unlist(parallel::mclapply(1:50, mc.cores = N_CORES,
  function(r) energy_once(shift = 0.2)))
add_check("Energy chain test, H1 shift 0.2 SD in one variable: power", NA,
  mean(e1 <= 0.05), criterion = "report")

# Output -------------------------------------------------------------------------
val <- bind_rows(checks)
write_tab(val, "c3_02_validation.csv")
print(as.data.frame(val))
cat("\nAll checks passed:", all(val$pass, na.rm = TRUE), "\n")
save_session("c3_02")
