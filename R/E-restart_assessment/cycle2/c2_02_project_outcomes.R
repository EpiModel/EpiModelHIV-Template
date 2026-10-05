# =============================================================================
# c2_02_project_outcomes.R
# Question : For the quantities the project actually uses (calibration
#            targets read 70 years after a restart; cumulative HIV incidence
#            over years 6-15 and incidence in year 15 of intervention runs),
#            how much of the stationary variance do runs from a single restart
#            point show, and how long must one wait? Answered two ways:
#              (a) directly on the 254 runs from x0, which was produced with
#                  OTHER parameters (c2_01): a parameter-change restart;
#              (b) lower bounds for a restart point drawn from pi under the
#                  SAME parameters (pseudo-restarts), with horizons to 80 y.
# Inputs   : data/run/restart_assessment/01_annual.rds (cycle 1)
# Outputs  : cycle2/results/tables/c2_02_*.csv, figures/c2_02_*.png,
#            data/run/restart_assessment/cycle2/c2_02_*.rds
# Method   : c2_METHODS.md C2-M2, C2-M3, C2-M4; results/c2_02_project_outcomes.md
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

target_vars <- unique(unname(target_map))
extra_vars <- c("prev", "prev.B", "prev.H", "prev.W", "incid_rate",
  "incid_rate.B", "incid_rate.H", "incid_rate.W", "num")
val_vars <- unique(c(target_vars, extra_vars))
cml_vars <- c("cml_incid", "cml_incid.B", "cml_incid.H", "cml_incid.W")

# (a) Direct, single x0: annual values -----------------------------------------
# Variance ratio and mean offset at every year, 95% chain-bootstrap CIs.
direct_val <- bind_rows(parallel::mclapply(val_vars, mc.cores = N_CORES,
  function(v) {
    f <- function(y) {
      pm <- pi_moments(y, pi_rows)
      cm <- cross_moments(y)
      c(cm$v / pm$s2, (cm$m - pm$mu) / sqrt(pm$s2),
        100 * (cm$m / pm$mu - 1))
    }
    est <- f(Y[[v]])
    ci <- boot_ci(chain_boot(n_c, N_BOOT, function(i) f(Y[[v]][, i])))
    n <- N_YEARS
    tibble(var = v, h = seq_len(n),
      r = est[1:n], r_lo = ci[1:n, 1], r_hi = ci[1:n, 2],
      o_sd = est[n + 1:n], o_lo = ci[n + 1:n, 1], o_hi = ci[n + 1:n, 2],
      o_pct = est[2 * n + 1:n])
  }))
saveRDS(direct_val, fs::path(INTER2_DIR, "c2_02_direct_values.rds"))

# Fit-based tolerance times for these variables (same method as cycle 1)
t_x0 <- bind_rows(parallel::mclapply(val_vars, mc.cores = N_CORES,
  function(v) {
    g <- function(y) {
      ft <- fit_times(y, pi_rows, fit_t, c(0.1, 0.2), c(0.1, 0.2))
      c(ft$t_var, ft$t_mean)
    }
    fo <- fit_times(Y[[v]], pi_rows, fit_t, c(0.1, 0.2), c(0.1, 0.2))
    ci <- boot_ci(chain_boot(n_c, 200, function(i) g(Y[[v]][, i])))
    tibble(var = v,
      stat = c("T_var_0.1", "T_var_0.2", "T_mean_0.1", "T_mean_0.2"),
      est = c(fo$t_var, fo$t_mean), lo = ci[, 1], hi = ci[, 2],
      var_model = fo$fv$model, var_tau1 = fo$fv$coef[2],
      var_tau2 = fo$fv$coef[4], mean_model = fo$fm$model,
      mean_tau1 = fo$fm$coef[2],
      mean_tau2 = if (fo$fm$model == "2exp") fo$fm$coef[4] else NA)
  }))
write_tab(t_x0, "c2_02_t_direct_x0.csv")

# (a) Direct, single x0: cumulative incidence windows -------------------------
# Sum over years B + 1 ... B + INT_L after restart, as in outcomes.R.
B_grid <- 0:100
direct_cml <- bind_rows(parallel::mclapply(cml_vars, mc.cores = N_CORES,
  function(v) {
    f <- function(y) {
      ref <- window_ref(y, INT_L, EQ_START, 1, "sum")
      M <- window_from_x0(y, INT_L, B_grid, "sum")
      mu_x0 <- rowMeans(M)
      v_x0 <- apply(M, 1, var)
      c(v_x0 / ref["var"], (mu_x0 - ref["mu"]) / sqrt(ref["var"]),
        100 * (mu_x0 / ref["mu"] - 1))
    }
    est <- f(Y[[v]])
    ci <- boot_ci(chain_boot(n_c, N_BOOT, function(i) f(Y[[v]][, i])))
    n <- length(B_grid)
    ref <- window_ref(Y[[v]], INT_L, EQ_START, 1, "sum")
    tibble(var = v, B = B_grid,
      between = est[1:n], between_lo = ci[1:n, 1], between_hi = ci[1:n, 2],
      o_sd = est[n + 1:n], o_lo = ci[n + 1:n, 1], o_hi = ci[n + 1:n, 2],
      o_pct = est[2 * n + 1:n], o_pct_lo = ci[2 * n + 1:n, 1],
      o_pct_hi = ci[2 * n + 1:n, 2],
      pi_mean = ref["mu"], pi_sd = sqrt(ref["var"]),
      pi_cv_pct = 100 * sqrt(ref["var"]) / ref["mu"])
  }))
write_tab(direct_cml, "c2_02_direct_cml_incidence.csv")

# Burn-in from the fitted between-run curve (as cycle 1, step 04)
cml_burnin <- bind_rows(parallel::mclapply(cml_vars, mc.cores = N_CORES,
  function(v) {
    g <- function(y) {
      ref <- window_ref(y, INT_L, EQ_START, 1, "sum")
      M <- window_from_x0(y, INT_L, B_grid, "sum")
      r <- apply(M, 1, var) / ref["var"]
      f <- fit_var_relax(B_grid, r)
      vapply(c(0.1, 0.2), function(e) t_from_fit(function(t) 1 - f$fn(t), e),
        numeric(1))
    }
    est <- g(Y[[v]])
    ci <- boot_ci(chain_boot(n_c, 200, function(i) g(Y[[v]][, i])))
    tibble(var = v, stat = c("B_between_0.1", "B_between_0.2"), est = est,
      lo = ci[, 1], hi = ci[, 2])
  }))
write_tab(cml_burnin, "c2_02_cml_burnin_direct.csv")

# (b) Same-parameter lower bounds (pseudo-restarts) ---------------------------
feat_vars <- dict$name[dict$block %in% c("key", "state")]
t0_max <- N_YEARS - max(max(H_LONG), max(B_LONG) + INT_L)
t0s <- seq(EQ_START + max(FEATURE_LAGS), t0_max, PSEUDO_RESTART_STEP)
rows <- restart_rows(t0s, n_c)
X <- restart_features(Y, feat_vars, rows, FEATURE_LAGS)
cat("Pseudo-restarts:", nrow(rows), " features:", ncol(X), "\n")

resp <- list()
meta <- list()
for (v in val_vars) {
  for (h in H_LONG) {
    nm <- paste0(v, "|value|", h)
    resp[[nm]] <- restart_value(Y[[v]], rows, h)
    meta[[nm]] <- tibble(var = v, functional = "value", h = h)
  }
}
for (v in cml_vars) {
  for (B in B_LONG) {
    nm <- paste0(v, "|cml10|", B)
    resp[[nm]] <- INT_L * restart_window(Y[[v]], rows, INT_L, B)$M
    meta[[nm]] <- tibble(var = v, functional = "cml10", h = B)
  }
}
R <- do.call(cbind, resp)
meta <- bind_rows(meta)
cat("Responses:", ncol(R), "\n")
pred <- ridge_cv(X, R, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
lb <- bind_cols(meta, bind_rows(parallel::mclapply(seq_len(ncol(R)),
  mc.cores = N_CORES, function(j) {
    b <- r2_boot(R[, j], pred[, j], mean(R[, j]), rows$chain, N_BOOT)
    tibble(lb = b[1], lb_lo = b[2], lb_hi = b[3])
  })))
write_tab(lb, "c2_02_lower_bounds.csv")

# Put the two views side by side at every horizon ------------------------------
cmp_val <- lb |>
  filter(functional == "value") |>
  left_join(direct_val |> transmute(var, h, icc_x0 = 1 - r,
    icc_x0_lo = 1 - r_hi, icc_x0_hi = 1 - r_lo), by = c("var", "h"))
cmp_cml <- lb |>
  filter(functional == "cml10") |>
  left_join(direct_cml |> transmute(var, h = B, icc_x0 = 1 - between,
    icc_x0_lo = 1 - between_hi, icc_x0_hi = 1 - between_lo),
    by = c("var", "h"))
cmp <- bind_rows(cmp_val, cmp_cml)
write_tab(cmp, "c2_02_icc_compare.csv")

# Time / burn-in needed: lower bound (same parameters) vs direct (x0) ---------
t_cmp <- bind_rows(lapply(split(cmp, list(cmp$var, cmp$functional),
  drop = TRUE), function(d) {
    tibble(var = d$var[1], functional = d$functional[1],
      eps = c(0.1, 0.2),
      T_lb_same_param = vapply(c(0.1, 0.2), function(e)
        t_from_bound(d$h, pmax(d$lb, 0), e), numeric(1)),
      T_direct_grid = vapply(c(0.1, 0.2), function(e)
        t_from_bound(d$h, d$icc_x0, e), numeric(1)))
  }))
write_tab(t_cmp, "c2_02_time_compare.csv")

# Figures ----------------------------------------------------------------------
show <- c("i.prev.dx.B", "i.prev.dx.H", "i.prev.dx.W", "prev", "dx_frac.B",
  "cc.vsupp.B", "prep_cov.B", "ir100.gono", "ir100.chla", "ir100.syph",
  "incid_rate", "num")
p <- cmp_val |>
  filter(var %in% show) |>
  ggplot(aes(h)) +
  geom_ribbon(aes(ymin = icc_x0_lo, ymax = icc_x0_hi), fill = "grey70",
    alpha = 0.5) +
  geom_line(aes(y = icc_x0, colour = "direct, x0 (other parameters)")) +
  geom_ribbon(aes(ymin = lb_lo, ymax = lb_hi), fill = "steelblue",
    alpha = 0.3) +
  geom_line(aes(y = lb, colour = "lower bound, same parameters")) +
  geom_point(aes(y = lb, colour = "lower bound, same parameters"),
    size = 0.8) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = 0.1, linetype = 3) +
  facet_wrap(~var, ncol = 4) +
  coord_cartesian(ylim = c(-0.2, 1)) +
  scale_colour_manual(values = c("black", "steelblue")) +
  labs(x = "Years after restart", y = "Share of variance fixed by the restart",
    colour = NULL,
    title = "Calibration targets and key outputs: restart memory by horizon") +
  theme(legend.position = "bottom")
save_fig(p, "c2_02_icc_targets.png", 13, 10)

p <- direct_cml |>
  ggplot(aes(B, between)) +
  geom_ribbon(aes(ymin = between_lo, ymax = between_hi), fill = "grey70",
    alpha = 0.5) +
  geom_line() +
  geom_point(data = cmp_cml, aes(h, 1 - lb), colour = "steelblue") +
  geom_errorbar(data = cmp_cml, aes(h, ymin = 1 - lb_hi, ymax = 1 - lb_lo),
    colour = "steelblue", width = 1, inherit.aes = FALSE) +
  geom_vline(xintercept = INT_B, linetype = 3) +
  geom_hline(yintercept = 1, linetype = 2) +
  facet_wrap(~var) +
  coord_cartesian(xlim = c(0, 80), ylim = c(0, 1.4)) +
  labs(x = "Years between restart and start of the 10-year window (B)",
    y = "Var(10-year cumulative incidence) / stationary value",
    title = "Cumulative HIV incidence over 10 years after a burn-in B",
    subtitle = paste0("Black: 254 runs from x0 (other parameters). Blue: ",
      "upper value 1 - lower bound, same parameters. Dotted: B = 5 ",
      "(intervention start)."))
save_fig(p, "c2_02_cml_incidence.png", 11, 7)

save_session("c2_02")
