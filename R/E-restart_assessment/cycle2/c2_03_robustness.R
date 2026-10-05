# =============================================================================
# c2_03_robustness.R
# Question : Do the cycle 1 conclusions depend on method choices? Checks:
#   (a) time to full variance with other estimators (stretched exponential,
#       nonparametric isotonic fit) vs the cycle 1 exponential fits;
#   (b) sensitivity to the period used as the pi reference;
#   (c) lower bounds with nonlinear features (does more memory appear?);
#   (d) memory longer than 150 years (variance-time at L = 225, 450);
#   (e) replication study: the detection rules and the fit-based times with
#       their bootstrap CIs, over 30 synthetic datasets per series;
#   (f) the cycle 1 claim "lower bound <= direct value".
# Inputs   : data/run/restart_assessment/01_annual.rds, cycle 1 tables
# Outputs  : cycle2/results/tables/c2_03_*.csv, figures/c2_03_*.png
# Method   : c2_METHODS.md C2-M3, C2-M5; results/c2_03_robustness.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle2/c2_config.R")
source("R/E-restart_assessment/cycle2/c2_utils.R")
set.seed(SEED)

annual <- readRDS(ANNUAL_PATH)
dict <- annual$dict
Y <- add_project_vars(annual$Y)
n_c <- ncol(Y[[1]])
pi_rows <- LATE_START:N_YEARS
fit_t <- 1:LATE_START
key <- dict$name[dict$block == "key"]
focus <- c("prev", "prev.B", "prev.H", "prev.W", "num", "incid_rate",
  "dx_frac", "supp_frac", "prep_cov", "gono_prev", "chla_prev", "syph_prev",
  "i.prev.dx.B", "i.prev.dx.H", "i.prev.dx.W")

# (a) Alternative estimators of T_var ------------------------------------------
alt_times <- function(y, eps) {
  pm <- pi_moments(y, pi_rows)
  r <- cross_moments(y[fit_t, , drop = FALSE])$v / pm$s2
  st <- fit_var_stretched(fit_t, r)
  ex <- fit_var_relax(fit_t, r)
  c(
    exp_fit = vapply(eps, function(e) t_from_fit(function(t) 1 - ex$fn(t), e),
      numeric(1)),
    stretched = vapply(eps, function(e)
      t_from_fit(function(t) 1 - st$fn(t), e), numeric(1)),
    isotonic = vapply(eps, function(e) iso_time(fit_t, r, e), numeric(1))
  )
}
eps <- c(0.1, 0.2)
alt <- bind_rows(parallel::mclapply(focus, mc.cores = N_CORES, function(v) {
  est <- alt_times(Y[[v]], eps)
  ci <- boot_ci(chain_boot(n_c, 200, function(i) alt_times(Y[[v]][, i], eps)))
  tibble(var = v,
    method = rep(c("exp_fit (cycle 1)", "stretched_exp", "isotonic"),
      each = length(eps)),
    eps = rep(eps, 3), est = est, lo = ci[, 1], hi = ci[, 2])
}))
write_tab(alt, "c2_03_t_var_methods.csv")

# (b) pi reference period -----------------------------------------------------
pi_sens <- bind_rows(lapply(focus, function(v) {
  bind_rows(lapply(c(150, 300, 450), function(start) {
    rows_pi <- start:N_YEARS
    pm <- pi_moments(Y[[v]], rows_pi)
    r <- cross_moments(Y[[v]][fit_t, , drop = FALSE])$v / pm$s2
    ex <- fit_var_relax(fit_t, r)
    tibble(var = v, pi_start = start, v_pi = pm$s2,
      v_pi_rel_to_300 = pm$s2 / pi_moments(Y[[v]], pi_rows)$s2,
      T_var_0.1 = t_from_fit(function(t) 1 - ex$fn(t), 0.1),
      T_var_0.2 = t_from_fit(function(t) 1 - ex$fn(t), 0.2))
  }))
}))
write_tab(pi_sens, "c2_03_pi_reference.csv")

# (c) Lower bounds with nonlinear features ------------------------------------
# Linear features as in cycle 1 plus the squares and pairwise products of the
# first 10 principal components of the standardised lag-0 features.
feat_vars <- dict$name[dict$block %in% c("key", "state")]
t0s <- seq(EQ_START + max(FEATURE_LAGS), N_YEARS - 40, PSEUDO_RESTART_STEP)
rows <- restart_rows(t0s, n_c)
X <- restart_features(Y, feat_vars, rows, FEATURE_LAGS)
X0 <- scale(restart_features(Y, feat_vars, rows))
pcs <- prcomp(X0, rank. = 10)$x
pairs <- combn(10, 2)
Xnl <- cbind(pcs^2, pcs[, pairs[1, ]] * pcs[, pairs[2, ]])
colnames(Xnl) <- paste0("nl", seq_len(ncol(Xnl)))
resp_def <- list(
  c("prev", "value", 10), c("prev", "value", 20), c("prev", "value", 30),
  c("i.prev.dx.B", "value", 20), c("i.prev.dx.W", "value", 20),
  c("dx_frac.B", "value", 5), c("ir100.gono", "value", 5),
  c("incid_rate", "value", 5), c("cml_incid", "cml10", 5),
  c("cml_incid.B", "cml10", 5)
)
Rr <- sapply(resp_def, function(d) {
  if (d[2] == "value") restart_value(Y[[d[1]]], rows, as.integer(d[3])) else
    INT_L * restart_window(Y[[d[1]]], rows, INT_L, as.integer(d[3]))$M
})
colnames(Rr) <- vapply(resp_def, paste, character(1), collapse = "|")
p_lin <- ridge_cv(X, Rr, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
p_nl <- ridge_cv(cbind(X, Xnl), Rr, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
nl <- bind_rows(lapply(seq_len(ncol(Rr)), function(j) {
  a <- r2_boot(Rr[, j], p_lin[, j], mean(Rr[, j]), rows$chain, N_BOOT)
  b <- r2_boot(Rr[, j], p_nl[, j], mean(Rr[, j]), rows$chain, N_BOOT)
  # paired difference by chain bootstrap
  res_a <- (Rr[, j] - p_lin[, j])^2
  res_b <- (Rr[, j] - p_nl[, j])^2
  tot <- (Rr[, j] - mean(Rr[, j]))^2
  byc <- rowsum(cbind(res_a, res_b, tot), rows$chain)
  dd <- replicate(N_BOOT, {
    i <- sample.int(nrow(byc), replace = TRUE)
    (sum(byc[i, 1]) - sum(byc[i, 2])) / sum(byc[i, 3])
  })
  tibble(response = colnames(Rr)[j], lb_linear = a[1], lb_nonlinear = b[1],
    gain = b[1] - a[1], gain_lo = quantile(dd, 0.025),
    gain_hi = quantile(dd, 0.975))
}))
write_tab(nl, "c2_03_nonlinear_bounds.csv")

# (d) Memory beyond 150 years ----------------------------------------------------
# L Var(M_L) / Var_pi on years 151-600 (450 years): L = 150, 225, 450.
# For an integrable ACF it plateaus at tau_int; still rising means longer
# memory. Chain means over 450 years are also checked for heavy tails.
Yeq <- lapply(Y[focus], function(y) y[(EQ_START + 1):N_YEARS, , drop = FALSE])
lm_tab <- bind_rows(parallel::mclapply(focus, mc.cores = N_CORES,
  function(v) {
    Ls <- c(75, 150, 225, 450)
    est <- variance_time(Yeq[[v]], Ls, 1)
    ci <- boot_ci(chain_boot(n_c, N_BOOT, function(i) {
      variance_time(Yeq[[v]][, i], Ls, 1)
    }))
    cm <- colMeans(Yeq[[v]])
    z <- (cm - mean(cm)) / sd(cm)
    tibble(var = v, L = Ls, vt = est, lo = ci[, 1], hi = ci[, 2],
      chain_mean_kurtosis = mean(z^4), chain_mean_shapiro_p =
        shapiro.test(cm)$p.value)
  }))
write_tab(lm_tab, "c2_03_long_memory.csv")

# (e) Replication study on synthetic data ------------------------------------------
# 30 datasets per series (254 chains x 600 years), each analysed as the real
# data: the brief's detection rule, the null-maximum rule, and the fit-based
# T_var(0.1), T_mean(0.1) with 95% chain-bootstrap CIs (100 refits).
n_y <- N_YEARS
ar1 <- function(a, s2 = 1, x0 = NULL) {
  sd_e <- sqrt(s2 * (1 - a^2))
  Ys <- matrix(0, n_y, n_c)
  prev <- if (is.null(x0)) rnorm(n_c, 0, sqrt(s2)) else rep(x0, n_c)
  for (t in seq_len(n_y)) {
    prev <- a * prev + rnorm(n_c, 0, sd_e)
    Ys[t, ] <- prev
  }
  Ys
}
series <- list(
  S0 = list(gen = function() ar1(0.9), t_var = 0, t_mean = 0),
  S1 = list(gen = function() ar1(0.9, x0 = 3),
    t_var = log(0.1) / (2 * log(0.9)), t_mean = log(0.1 / 3) / log(0.9)),
  S2 = list(gen = function() ar1(0.5, 0.9, x0 = 0) + ar1(0.98, 0.1, x0 = 0),
    t_var = uniroot(function(t) 0.9 * 0.25^t + 0.1 * 0.98^(2 * t) - 0.1,
      c(0, 100))$root, t_mean = 0)
)
one_rep <- function(s) {
  S <- series[[s]]
  Ys <- S$gen()
  z <- (Ys - pi_moments(Ys, pi_rows)$mu) / sqrt(pi_moments(Ys, pi_rows)$s2)
  D <- rowMeans(energy_trajectory(array(z, c(n_y, n_c, 1)), 1:n_y,
    REF_YEARS, 10))
  q <- quantile(D[LATE_START:n_y], T_Q)
  ft <- function(y) {
    f <- fit_times(y, pi_rows, fit_t, 0.1, 0.1)
    c(f$t_var, f$t_mean)
  }
  est <- ft(Ys)
  ci <- boot_ci(chain_boot(n_c, N_BOOT_REP, function(i) ft(Ys[, i])))
  tibble(series = s,
    rule_brief = t_rule(D, 1:n_y, q, LATE_START, T_Q, T_MAX_RUN),
    rule_nullmax = t_full_rule(D, LATE_START, SMOOTH_W, "max")$t,
    t_var = est[1], t_var_lo = ci[1, 1], t_var_hi = ci[1, 2],
    t_mean = est[2], t_mean_lo = ci[2, 1], t_mean_hi = ci[2, 2],
    true_t_var = S$t_var, true_t_mean = S$t_mean)
}
rep_res <- bind_rows(parallel::mclapply(
  rep(names(series), each = N_REP_SIM), one_rep, mc.cores = N_CORES))
write_tab(rep_res, "c2_03_replication_raw.csv")
rep_sum <- rep_res |>
  summarise(
    n = n(),
    rule_brief_median = median(rule_brief, na.rm = TRUE),
    rule_brief_iqr = paste(quantile(rule_brief, c(0.25, 0.75), na.rm = TRUE),
      collapse = "-"),
    rule_brief_na = sum(is.na(rule_brief)),
    rule_nullmax_median = median(rule_nullmax),
    rule_nullmax_iqr = paste(quantile(rule_nullmax, c(0.25, 0.75)),
      collapse = "-"),
    t_var_true = first(true_t_var),
    t_var_median = median(t_var),
    t_var_cover = mean(true_t_var >= t_var_lo & true_t_var <= t_var_hi),
    t_mean_true = first(true_t_mean),
    t_mean_median = median(t_mean),
    t_mean_cover = mean(true_t_mean >= t_mean_lo & true_t_mean <= t_mean_hi),
    .by = series
  )
write_tab(rep_sum, "c2_03_replication_summary.csv")
print(as.data.frame(rep_sum))

# (f) Cycle 1 claim: lower bound <= direct value -------------------------------
c1 <- read.csv(fs::path(C1_TAB_DIR, "06_icc_bounds.csv")) |>
  filter(!is.na(icc_x0), h > 0)
claim <- c1 |>
  mutate(lb_above_direct = icc_lb > icc_x0,
    lb_above_direct_ci = r2_full_lo > icc_x0_hi) |>
  summarise(n = n(), n_lb_above = sum(lb_above_direct),
    n_lb_above_beyond_ci = sum(lb_above_direct_ci), .by = functional)
write_tab(claim, "c2_03_claim_lb_vs_direct.csv")
write_tab(c1 |> filter(r2_full_lo > icc_x0_hi) |>
  select(var, functional, h, icc_lb, r2_full_lo, icc_x0, icc_x0_hi),
  "c2_03_claim_lb_vs_direct_cases.csv")

# Figure: T_var by method ---------------------------------------------------------
p <- alt |>
  filter(eps == 0.1) |>
  mutate(var = factor(var, rev(focus))) |>
  ggplot(aes(est, var, colour = method)) +
  geom_errorbarh(aes(xmin = lo, xmax = pmin(hi, 300)), height = 0.3,
    position = position_dodge(width = 0.6)) +
  geom_point(position = position_dodge(width = 0.6)) +
  coord_cartesian(xlim = c(0, 300)) +
  labs(x = "Years after restart until the variance deficit stays <= 10%",
    y = NULL, colour = NULL,
    title = "Time to full variance from x0: three estimators",
    subtitle = "95% chain-bootstrap CIs (upper limits truncated at 300)")
save_fig(p, "c2_03_t_var_methods.png", 9, 7)

save_session("c2_03")
