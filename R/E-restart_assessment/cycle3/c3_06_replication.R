# =============================================================================
# c3_06_replication.R
# Question : Do the independent cold-start runs reproduce the equilibrium
#            time structure (ACF, tau_int, variance split of 20-year runs) and
#            the restart-memory lower bounds of cycles 1-2? The two
#            experiments have different stationary laws (c3_03), so the
#            question is whether the dynamics, not the levels, carry over.
# Inputs   : data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            data/run/restart_assessment/01_annual.rds (cycle 1, read-only),
#            cycle3/results/tables/c3_04_eq_start.csv,
#            results/tables/05_tau_int.csv, 06_icc_bounds.csv (cycle 1)
# Outputs  : cycle3/results/tables/c3_06_*.csv, figures/c3_06_*.png
# Method   : METHODS.md M2.3, M2.6, M2.7; results/c3_06_replication.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

eq <- read.csv(fs::path(TAB_DIR, "c3_04_eq_start.csv"))
if (EQ_START_C3 < eq$eq_start_rule) {
  stop("EQ_START_C3 (", EQ_START_C3, ") is earlier than the c3_04 rule (",
    eq$eq_start_rule, ")")
}
cold <- readRDS(COLD_ANNUAL_PATH)
dict <- cold$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
# Both experiments on the same years, so that estimators with a length-
# dependent truncation (Geyer, variance-time) are compared like for like
yrs <- EQ_START_C3:N_YEARS
data <- list(
  `cold start` = cold$Y,
  `x0 restart` = add_project_vars(readRDS(X0_ANNUAL_PATH)$Y)
)
rm(cold)
vars <- c(key, "i.prev.dx.B", "i.prev.dx.H", "i.prev.dx.W")

# Pooled ACF and tau_int (M2.6) ----------------------------------------------------
# Global mean and variance, Geyer's initial monotone sequence, chain
# bootstrap via the exact per-chain decomposition. The two datasets are
# independent, so differences of bootstrap replicates bootstrap the
# difference.
LAGS <- c(1, 5, 10, 20, 50)
acf_boot <- function(y) {
  parts <- acf_parts(y[yrs, , drop = FALSE], ACF_MAX_LAG)
  f <- function(i) {
    r <- acf_from_parts(parts, i)
    g <- tau_geyer(r)
    c(g$tau, r[LAGS + 1], g$truncated)
  }
  list(est = f(seq_len(ncol(y))),
    bm = do.call(rbind, lapply(seq_len(N_BOOT), function(b) {
      f(sample.int(ncol(y), ncol(y), replace = TRUE))
    })))
}
acf_res <- lapply(data, function(Y) {
  parallel::mclapply(setNames(vars, vars), mc.cores = N_CORES,
    function(v) acf_boot(Y[[v]]))
})
k <- 1 + length(LAGS)
tau <- bind_rows(lapply(vars, function(v) {
  a <- acf_res[[1]][[v]]
  b <- acf_res[[2]][[v]]
  d <- a$bm[, 1:k] - b$bm[, 1:k]
  tibble(var = v, stat = c("tau_int", paste0("rho_", LAGS)),
    cold = a$est[1:k], cold_lo = apply(a$bm[, 1:k], 2, quantile, 0.025),
    cold_hi = apply(a$bm[, 1:k], 2, quantile, 0.975),
    x0 = b$est[1:k], x0_lo = apply(b$bm[, 1:k], 2, quantile, 0.025),
    x0_hi = apply(b$bm[, 1:k], 2, quantile, 0.975),
    diff = a$est[1:k] - b$est[1:k], diff_lo = apply(d, 2, quantile, 0.025),
    diff_hi = apply(d, 2, quantile, 0.975),
    truncated_cold = c(a$est[k + 1] == 1, rep(NA, length(LAGS))),
    truncated_x0 = c(b$est[k + 1] == 1, rep(NA, length(LAGS))))
}))
tau_c1 <- read.csv(fs::path(C1_TAB_DIR, "05_tau_int.csv")) |>
  transmute(var, stat = "tau_int", x0_cycle1_150_600 = tau_int)
tau <- left_join(tau, tau_c1, by = c("var", "stat"))
write_tab(tau, "c3_06_acf_tau.csv")

# Variance-time curve and the split of a 20-year run (M2.7) -------------------------
vt_split <- function(y, i) {
  z <- y[yrs, i, drop = FALSE]
  s <- window_split(z, WINDOW_L, 1)
  c(variance_time(z, VT_L_GRID, 1), s["between"] / s["total"])
}
nL <- length(VT_L_GRID)
vt <- bind_rows(lapply(vars, function(v) {
  r <- lapply(data, function(Y) {
    y <- Y[[v]]
    n <- ncol(y)
    list(est = vt_split(y, seq_len(n)),
      bm = do.call(rbind, parallel::mclapply(seq_len(N_BOOT),
        mc.cores = N_CORES, function(b) {
          vt_split(y, sample.int(n, n, replace = TRUE))
        })))
  })
  d <- r[[1]]$bm - r[[2]]$bm
  tibble(var = v, stat = c(paste0("vt_L", VT_L_GRID), "between_frac_L20"),
    cold = r[[1]]$est, cold_lo = apply(r[[1]]$bm, 2, quantile, 0.025),
    cold_hi = apply(r[[1]]$bm, 2, quantile, 0.975),
    x0 = r[[2]]$est, x0_lo = apply(r[[2]]$bm, 2, quantile, 0.025),
    x0_hi = apply(r[[2]]$bm, 2, quantile, 0.975),
    diff = r[[1]]$est - r[[2]]$est, diff_lo = apply(d, 2, quantile, 0.025),
    diff_hi = apply(d, 2, quantile, 0.975))
}))
write_tab(vt, "c3_06_variance_time_split.csv")

# Restart-memory lower bounds (M2.3) ---------------------------------------------------
# Pseudo-restarts every PSEUDO_RESTART_STEP years in the stationary years of
# each experiment (same years for both), features = key and state variables
# at t0, t0 - 1, t0 - 2, t0 - 5; ridge with chain-blocked CV and the
# own-value model, as cycle 1 step 06. Responses: values at h years, 20-year
# window means after a burn-in B, and the project's 10-year cumulative
# incidence (years t0 + 6 ... t0 + 15).
H_REP <- c(5, 10, 20, 30)
B_REP <- c(0, 10, 20)
t0s <- seq(EQ_START_C3 + max(FEATURE_LAGS),
  N_YEARS - max(max(H_REP), max(B_REP) + WINDOW_L, INT_END), PSEUDO_RESTART_STEP)
cml <- c("hiv.incid", "hiv.incid.B", "hiv.incid.H", "hiv.incid.W")
bounds <- bind_rows(lapply(names(data), function(lab) {
  Y <- data[[lab]]
  rows <- restart_rows(t0s, ncol(Y[[1]]))
  X <- restart_features(Y, c(key, state), rows, FEATURE_LAGS)
  resp <- list()
  meta <- list()
  for (v in vars) {
    for (h in H_REP) {
      nm <- paste0(v, "|value|", h)
      resp[[nm]] <- restart_value(Y[[v]], rows, h)
      meta[[nm]] <- tibble(var = v, functional = "value", h = h)
    }
    for (B in B_REP) {
      nm <- paste0(v, "|M|", B)
      resp[[nm]] <- restart_window(Y[[v]], rows, WINDOW_L, B)$M
      meta[[nm]] <- tibble(var = v, functional = "window_mean", h = B)
    }
  }
  for (v in cml) {
    nm <- paste0(v, "|cml10|", INT_B)
    resp[[nm]] <- INT_L * restart_window(Y[[v]], rows, INT_L, INT_B)$M
    meta[[nm]] <- tibble(var = v, functional = "cml10", h = INT_B)
  }
  R <- do.call(cbind, resp)
  meta <- bind_rows(meta)
  cat(lab, ": pseudo-restarts", nrow(rows), " features", ncol(X),
    " responses", ncol(R), "\n")
  pred_full <- ridge_cv(X, R, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
  pred_own <- R
  for (v in unique(meta$var)) {
    cols <- which(meta$var == v)
    Xo <- restart_features(Y, v, rows)
    pred_own[, cols] <- ridge_cv(Xo, R[, cols, drop = FALSE], rows$chain,
      CV_FOLDS, RIDGE_LAMBDAS)
  }
  r2 <- bind_rows(parallel::mclapply(seq_len(ncol(R)), mc.cores = N_CORES,
    function(j) {
      f <- r2_boot(R[, j], pred_full[, j], mean(R[, j]), rows$chain, N_BOOT)
      o <- r2_boot(R[, j], pred_own[, j], mean(R[, j]), rows$chain, N_BOOT)
      tibble(r2_full = f[1], r2_full_lo = f[2], r2_full_hi = f[3],
        r2_own = o[1], r2_own_lo = o[2], r2_own_hi = o[3])
    }))
  bind_cols(tibble(start = lab), meta, r2) |>
    mutate(icc_lb = pmax(0, r2_full, r2_own),
      icc_lb_lo = pmax(0, ifelse(r2_full >= r2_own, r2_full_lo, r2_own_lo)),
      icc_lb_hi = pmax(0, ifelse(r2_full >= r2_own, r2_full_hi, r2_own_hi)))
}))
write_tab(bounds, "c3_06_icc_bounds.csv")

c1 <- read.csv(fs::path(C1_TAB_DIR, "06_icc_bounds.csv")) |>
  filter((functional == "value" & h %in% H_REP) |
    (functional == "window_mean" & h %in% B_REP)) |>
  transmute(var, functional, h, x0_cycle1 = icc_lb)
icc_cmp <- bounds |>
  select(start, var, functional, h, icc_lb, icc_lb_lo, icc_lb_hi) |>
  tidyr::pivot_wider(names_from = start,
    values_from = c(icc_lb, icc_lb_lo, icc_lb_hi)) |>
  left_join(c1, by = c("var", "functional", "h"))
write_tab(icc_cmp, "c3_06_icc_compare.csv")

# Figures ----------------------------------------------------------------------
p <- tau |>
  filter(stat == "tau_int") |>
  tidyr::pivot_longer(c(cold, x0), names_to = "start") |>
  mutate(lo = ifelse(start == "cold", cold_lo, x0_lo),
    hi = ifelse(start == "cold", cold_hi, x0_hi),
    start = recode(start, cold = "cold start", x0 = "x0 restart"),
    var = factor(var, rev(vars))) |>
  ggplot(aes(value, var, colour = start)) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0, orientation = "y",
    position = position_dodge(width = 0.5)) +
  geom_point(position = position_dodge(width = 0.5)) +
  scale_x_log10() +
  labs(x = "tau_int (years, log scale), Geyer", y = NULL, colour = NULL,
    title = paste0("Integrated autocorrelation time, years ", min(yrs), "-",
      max(yrs), " of each experiment"))
save_fig(p, "c3_06_tau_int.png", 9, 10)

p <- icc_cmp |>
  filter(functional %in% c("value", "window_mean")) |>
  mutate(panel = ifelse(functional == "value", paste0("value, h = ", h),
    paste0("20-year mean, B = ", h))) |>
  ggplot(aes(`icc_lb_x0 restart`, `icc_lb_cold start`)) +
  geom_abline(linetype = 2) +
  geom_errorbar(aes(ymin = `icc_lb_lo_cold start`,
    ymax = `icc_lb_hi_cold start`), alpha = 0.4, width = 0) +
  geom_point(size = 1) +
  facet_wrap(~panel, ncol = 4) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Lower bound on ICC, x0 runs", y = "Lower bound on ICC, cold start",
    title = "Restart-memory lower bounds in the two experiments (same years)",
    subtitle = "One point per key variable; bars: 95% CI (cold start)")
save_fig(p, "c3_06_icc_compare.png", 13, 8)

save_session("c3_06")
