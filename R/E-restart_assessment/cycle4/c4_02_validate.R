# =============================================================================
# c4_02_validate.R
# Question : Do the cycle 4 estimators recover known answers on synthetic
#            nested data of the same shape (32 restart points drawn from pi,
#            the actual runs per point, 600 years)?
#              - direct ICC(h) (icc_w and icc_a) and its point-bootstrap CI;
#              - the ICC of 20-year window means after a burn-in B;
#              - the time to full variance from one point, from a fit;
#              - the pool variance formula;
#              - the one-year-change continuity test under H0 and H1.
# Inputs   : data/run/restart_assessment/cycle4/c4_01_annual_pool.rds (only
#            the runs per point)
# Outputs  : cycle4/results/tables/c4_02_validation.csv
# Method   : c4_METHODS.md C4-M2 to C4-M4; results/c4_02_validate.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
source("R/E-restart_assessment/cycle4/c4_config.R")
source("R/E-restart_assessment/cycle4/c4_utils.R")
set.seed(SEED)

nj <- readRDS(POOL_ANNUAL_PATH)$n_per_point
g <- rep(seq_along(nj), times = nj) # runs grouped by point, as in the data
N <- length(g)
k <- length(nj)
n_y <- N_YEARS
pi_rows <- LATE_START:n_y
B_VAL <- 200

# Synthetic nested data --------------------------------------------------------------
# Sum of AR(1) components with stationary variances v (sum 1). Each point is
# a draw of the component states from pi; every run from a point continues
# independently. Truths, with Sigma v = 1:
#   ICC(h)              = sum_k v_k a_k^(2h)
#   ICC of M_L after B  = sum_k v_k c_k(B)^2 / sum_k v_k w_k, with
#     c_k(B) = a_k^(B+1) (1 - a_k^L) / (L (1 - a_k)),
#     w_k    = (L + 2 sum_{j<L} (L - j) a_k^j) / L^2.
# Year 0 (row 1 of the output) is the restart state itself.
nested_ar <- function(a, v, shift = 0) {
  Y <- matrix(0, n_y, N)
  last <- numeric(k) # value of the restart state (the source's last year)
  for (c in seq_along(a)) {
    x0 <- rnorm(k, 0, sqrt(v[c]))
    sd_e <- sqrt(v[c] * (1 - a[c]^2))
    last <- last + x0
    x <- x0[g]
    for (t in seq_len(n_y)) {
      x <- a[c] * x + rnorm(N, 0, sd_e)
      Y[t, ] <- Y[t, ] + x
    }
  }
  list(Y = Y + shift, last = last)
}
truth_icc <- function(a, v, h) {
  out <- 0
  for (c in seq_along(a)) out <- out + v[c] * a[c]^(2 * h)
  out / sum(v)
}
truth_icc_M <- function(a, v, B, L = WINDOW_L) {
  num <- den <- 0
  for (c in seq_along(a)) {
    j <- 1:(L - 1)
    cB <- a[c]^(B + 1) * (1 - a[c]^L) / (L * (1 - a[c]))
    num <- num + v[c] * cB^2
    den <- den + v[c] * (L + 2 * sum((L - j) * a[c]^j)) / L^2
  }
  num / den
}

checks <- list()
add_check <- function(check, truth, est, lo = NA, hi = NA, criterion) {
  z <- if (!is.na(lo)) (est - truth) / ((hi - lo) / 3.92) else NA_real_
  pass <- if (criterion == "in CI") {
    abs(z) < 3
  } else if (grepl("^range", criterion)) {
    r <- as.numeric(strsplit(sub("range ", "", criterion), " to ")[[1]])
    est >= r[1] & est <= r[2]
  } else {
    NA
  }
  checks[[length(checks) + 1]] <<- tibble(check, truth, est, lo, hi, z,
    criterion, pass)
}

# Direct ICC at horizons (C4-M2) ----------------------------------------------------
# S1: one slow AR(1) (a = 0.97, like prevalence); S2: fast 60% (a = 0.6) +
# slow 40% (a = 0.97), like an output with short- and long-term memory.
series <- list(S1 = list(a = 0.97, v = 1), S2 = list(a = c(0.6, 0.97),
  v = c(0.6, 0.4)))
hs <- c(1, 5, 10, 20, 50)
for (s in names(series)) {
  a <- series[[s]]$a
  v <- series[[s]]$v
  sim <- nested_ar(a, v)
  f <- function(runs, gg) {
    y <- sim$Y[, runs, drop = FALSE]
    vp <- pi_moments(y, pi_rows)$s2
    d <- icc_direct(y[hs, , drop = FALSE], gg, vp)
    c(d[, "icc_w"], d[, "icc_a"])
  }
  est <- f(seq_len(N), g)
  ci <- boot_ci(do.call(rbind, lapply(seq_len(B_VAL), function(b) {
    bi <- point_boot_index(g)
    f(bi$runs, bi$g)
  })))
  for (j in seq_along(hs)) {
    tr <- truth_icc(a, v, hs[j])
    add_check(paste0(s, " icc_w(", hs[j], ")"), tr, est[j], ci[j, 1],
      ci[j, 2], "in CI")
    jj <- length(hs) + j
    add_check(paste0(s, " icc_a(", hs[j], ")"), tr, est[jj], ci[jj, 1],
      ci[jj, 2], "in CI")
  }
  # 20-year window means after a burn-in B
  for (B in c(0, 20)) {
    fM <- function(runs, gg) {
      y <- sim$Y[, runs, drop = FALSE]
      M <- window_from_x0(y, WINDOW_L, B, "mean")
      ref <- window_ref(y, WINDOW_L, LATE_START, 1, "mean")
      icc_direct(M, gg, ref["var"])[, "icc_w"]
    }
    estM <- fM(seq_len(N), g)
    ciM <- quantile(vapply(seq_len(B_VAL), function(b) {
      bi <- point_boot_index(g)
      fM(bi$runs, bi$g)
    }, numeric(1)), c(0.025, 0.975))
    add_check(paste0(s, " icc_w of the 20-year mean, B = ", B),
      truth_icc_M(a, v, B), estM, ciM[1], ciM[2], "in CI")
  }
}

# Time to full variance from one point (C4-M2) --------------------------------------
# w(h) = sw2(h) / v_pi = 1 - ICC(h), fitted with the cycle 3 variance model;
# T(eps) = year after which the fitted 1 - w stays <= eps. S2 truth by
# root finding.
a <- series$S2$a
v <- series$S2$v
sim <- nested_ar(a, v)
t_one <- function(runs, gg) {
  y <- sim$Y[, runs, drop = FALSE]
  vp <- pi_moments(y, pi_rows)$s2
  w <- icc_direct(y[1:H_MAX, , drop = FALSE], gg, vp)[, "w_ratio"]
  fv <- fit_var_relax_c3(1:H_MAX, w)
  vapply(c(0.1, 0.2), function(e) t_from_fit(function(t) 1 - fv$fn(t), e),
    numeric(1))
}
est <- t_one(seq_len(N), g)
ci <- boot_ci(do.call(rbind, lapply(seq_len(B_VAL), function(b) {
  bi <- point_boot_index(g)
  t_one(bi$runs, bi$g)
})))
for (j in 1:2) {
  e <- c(0.1, 0.2)[j]
  tr <- t_from_fit(function(t) truth_icc(a, v, t), e)
  add_check(paste0("S2 one point: time to full variance, eps = ", e), tr,
    est[j], ci[j, 1], ci[j, 2], "in CI")
}

# Coverage over replications (C4-M2) -------------------------------------------------
R_COV <- 50
a <- series$S1$a
v <- series$S1$v
tr10 <- truth_icc(a, v, 10)
cov <- do.call(rbind, parallel::mclapply(seq_len(R_COV), mc.cores = N_CORES,
  function(r) {
    s <- nested_ar(a, v)
    f <- function(runs, gg) {
      y <- s$Y[, runs, drop = FALSE]
      vp <- pi_moments(y, pi_rows)$s2
      d <- icc_direct(y[10, , drop = FALSE], gg, vp)
      c(d[, "icc_w"], d[, "icc_a"], var(y[10, ]) / vp)
    }
    est <- f(seq_len(N), g)
    bm <- do.call(rbind, lapply(1:200, function(b) {
      bi <- point_boot_index(g)
      f(bi$runs, bi$g)
    }))
    ci <- boot_ci(bm[, 1:2])
    c(est, tr10 >= ci[1, 1] & tr10 <= ci[1, 2],
      tr10 >= ci[2, 1] & tr10 <= ci[2, 2])
  }))
add_check("S1 icc_w(10): mean over 50 replications", tr10, mean(cov[, 1]),
  mean(cov[, 1]) - 1.96 * sd(cov[, 1]) / sqrt(R_COV),
  mean(cov[, 1]) + 1.96 * sd(cov[, 1]) / sqrt(R_COV), "in CI")
add_check("S1 icc_a(10): mean over 50 replications", tr10, mean(cov[, 2]),
  mean(cov[, 2]) - 1.96 * sd(cov[, 2]) / sqrt(R_COV),
  mean(cov[, 2]) + 1.96 * sd(cov[, 2]) / sqrt(R_COV), "in CI")
add_check("S1 icc_w(10): coverage of the 95% CI", 0.95, mean(cov[, 4]),
  criterion = "range 0.85 to 1")
add_check("S1 icc_a(10): coverage of the 95% CI", 0.95, mean(cov[, 5]),
  criterion = "range 0.85 to 1")
# The pool formula: E[across-run variance] / V at h = 10 for these counts
add_check("Pool variance ratio at h = 10 (mean over 50 replications)",
  pool_var_ratio(tr10, nj), mean(cov[, 3]),
  mean(cov[, 3]) - 1.96 * sd(cov[, 3]) / sqrt(R_COV),
  mean(cov[, 3]) + 1.96 * sd(cov[, 3]) / sqrt(R_COV), "in CI")

# Continuity test: one-year change at the restart (C4-M3) ----------------------------
# D_i = (first year of run i) - (last year of its source chain). Under a
# seamless restart D has mean 0 and the variance of a stationary one-year
# change. Test: mean(D) against 0 with a point-bootstrap CI.
cont_once <- function(shift) {
  s <- nested_ar(0.97, 1, shift = 0)
  D <- s$Y[1, ] + shift - s$last[g]
  bm <- vapply(1:200, function(b) {
    bi <- point_boot_index(g)
    mean(D[bi$runs])
  }, numeric(1))
  q <- quantile(bm, c(0.025, 0.975))
  q[1] > 0 | q[2] < 0
}
rej0 <- mean(unlist(parallel::mclapply(1:200, mc.cores = N_CORES,
  function(r) cont_once(0))))
add_check("Continuity test, H0: rejection rate (200 reps, 5% level)", 0.05,
  rej0, criterion = "range 0.02 to 0.09")
rej1 <- mean(unlist(parallel::mclapply(1:100, mc.cores = N_CORES,
  function(r) cont_once(0.1))))
add_check("Continuity test, H1 jump of 0.1 SD: power (100 reps)", NA, rej1,
  criterion = "report")

# Output -------------------------------------------------------------------------
val <- bind_rows(checks)
write_tab(val, "c4_02_validation.csv")
print(as.data.frame(val))
cat("\nAll checks passed:", all(val$pass, na.rm = TRUE), "\n")
save_session("c4_02")
