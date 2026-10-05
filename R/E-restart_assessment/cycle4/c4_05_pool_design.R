# =============================================================================
# c4_05_pool_design.R
# Question : With the direct ICC (c4_04) instead of lower bounds or one x0:
#   (a) does the actual 32-point pool give runs with the full stationary
#       spread, and how large is its shared imprint (the pool-mean error)?
#   (b) how many points, and how many runs per point, are needed for the
#       project's outcomes, for balanced and randomised assignment?
#   (c) how long is the burn-in after a restart with k points?
# Inputs   : data/run/restart_assessment/cycle4/c4_01_annual_pool.rds,
#            data/run/restart_assessment/cycle4/c4_04_icc.rds,
#            results/tables/07_k_needed.csv (cycle 1),
#            cycle2/results/tables/c2_04_intervention_design.csv
# Outputs  : cycle4/results/tables/c4_05_*.csv, figures/c4_05_*.png
# Method   : c4_METHODS.md C4-M4; results/c4_05_pool_design.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle4/c4_config.R")
source("R/E-restart_assessment/cycle4/c4_utils.R")
set.seed(SEED)

pool <- readRDS(POOL_ANNUAL_PATH)
icc <- readRDS(fs::path(INTER4_DIR, "c4_04_icc.rds"))
dict <- pool$dict
key <- dict$name[dict$block == "key"]
g <- pool$point
nj <- pool$n_per_point
N <- length(g)
pi_rows <- LATE_START:N_YEARS
hs <- seq_len(H_MAX)

# (a) The realised pool: spread and imprint of all 256 runs (C4-M4) --------------
# Across-run variance / v_pi and mean offset in SD_pi at each year h, with
# point-bootstrap CIs. Expected variance ratio for these counts from the
# direct ICC: 1 - ICC(h) (sum n_j^2 / N - 1) / (N - 1). The offset is the
# error of the pool mean: the shared imprint of the 32 points plus the
# sampling error of 256 runs. Its expected RMS (points iid from pi) is the
# MCSE of the mean, sqrt((1 + ICC(h) (sum n_j^2 / N - 1)) / N) SD_pi.
pool_curve <- function(y, runs) {
  yy <- y[, runs, drop = FALSE]
  pm <- pi_moments(yy, pi_rows)
  z <- yy[hs, , drop = FALSE]
  c(apply(z, 1, var) / pm$s2, (rowMeans(z) - pm$mu) / sqrt(pm$s2))
}
nh <- length(hs)
realised <- bind_rows(parallel::mclapply(key, mc.cores = N_CORES, function(v) {
  y <- pool$Y[[v]]
  est <- pool_curve(y, seq_len(N))
  ci <- boot_ci(do.call(rbind, lapply(seq_len(N_BOOT_PT), function(b) {
    pool_curve(y, point_boot_index(g)$runs)
  })))
  ic <- icc |> filter(var == v, functional == "value")
  tibble(var = v, h = hs,
    var_ratio = est[1:nh], var_lo = ci[1:nh, 1], var_hi = ci[1:nh, 2],
    var_expected = pool_var_ratio(pmax(ic$icc_w, 0), nj),
    offset = est[nh + 1:nh], offset_lo = ci[nh + 1:nh, 1],
    offset_hi = ci[nh + 1:nh, 2],
    offset_rms_expected = sqrt((1 + pmax(ic$icc_w, 0) *
      (sum(nj^2) / N - 1)) / N))
}))
write_tab(realised, "c4_05_realised_pool.csv")

# (b) Pool size for the project's outcomes (C4-M4) --------------------------------
# Outcomes: 20-year means at B = 0; 10-year cumulative incidence at B = 5
# (years 6-15, outcomes.R); values in year 15 and year 70. ICC = icc_w with
# its 95% CI (the formulas are monotone in ICC, so the CI carries over).
#   balanced, n = N / k runs per point:
#     deficit = ICC (1 - n (k - 1) / (N - 1)); inflation = sqrt(1 + ICC (n - 1))
#     points for inflation <= 1 + g: k >= N ICC / ((1 + g)^2 - 1 + ICC)
#   randomize.restart (draws with replacement):
#     E[sum n_j^2 / N] = N / k + 1 - 1 / k; inflation = sqrt(1 + ICC (N - 1) / k)
#     points for inflation <= 1 + g: k >= ICC (N - 1) / ((1 + g)^2 - 1)
outc <- bind_rows(
  tibble(var = c("prev", "prev.B", "i.prev.dx.B", "num", "incid_rate",
    "dx_frac", "supp_frac", "prep_cov", "gono_prev", "chla_prev",
    "syph_prev"), functional = "M20", h = 0),
  tibble(var = c("hiv.incid", "hiv.incid.B", "hiv.incid.H", "hiv.incid.W"),
    functional = "cml10", h = INT_B),
  tibble(var = rep(c("prev", "i.prev.dx.B", "i.prev.dx.H", "i.prev.dx.W",
    "incid_rate", "ir100.gono", "ir100.chla", "ir100.syph"), 2),
    functional = "value", h = rep(c(INT_END, CALIB_H), each = 8))
) |>
  left_join(icc |> select(var, functional, h, icc_w, icc_w_lo, icc_w_hi),
    by = c("var", "functional", "h")) |>
  mutate(across(c(icc_w, icc_w_lo, icc_w_hi), ~ pmin(pmax(.x, 0), 1)))
k_bal <- function(c, Nr, gg) ceiling(Nr * c / ((1 + gg)^2 - 1 + c))
k_rnd <- function(c, Nr, gg) ceiling(c * (Nr - 1) / ((1 + gg)^2 - 1))
design <- bind_rows(lapply(PLANNED_N_C4, function(Nr) {
  bind_rows(lapply(INFL_TOL, function(gg) {
    outc |> mutate(N = Nr, tolerance = gg,
      k_balanced = k_bal(icc_w, Nr, gg),
      k_balanced_lo = k_bal(icc_w_lo, Nr, gg),
      k_balanced_hi = k_bal(icc_w_hi, Nr, gg),
      k_random = pmax(k_rnd(icc_w, Nr, gg), 1),
      k_random_lo = pmax(k_rnd(icc_w_lo, Nr, gg), 1),
      k_random_hi = pmax(k_rnd(icc_w_hi, Nr, gg), 1))
  }))
}))
write_tab(design, "c4_05_points_needed.csv")

# MCSE inflation and variance deficit for the pool sizes of the project
mcse <- bind_rows(lapply(PLANNED_N_C4, function(Nr) {
  bind_rows(lapply(POOL_K_C4[POOL_K_C4 <= Nr], function(k) {
    n <- Nr / k
    outc |> mutate(N = Nr, k = k,
      inflation_balanced = sqrt(1 + icc_w * (n - 1)),
      inflation_random = sqrt(1 + icc_w * (n_eff_random(Nr, k) - 1)),
      deficit_balanced = icc_w * (1 - n * (k - 1) / (Nr - 1)),
      deficit_random = icc_w * (n_eff_random(Nr, k) - 1) / (Nr - 1),
      effective_runs_balanced = Nr / (1 + icc_w * (n - 1)),
      effective_runs_random = Nr / (1 + icc_w * (n_eff_random(Nr, k) - 1)),
      # with k points the effective runs never exceed k / ICC
      effective_runs_cap = k / icc_w)
  }))
}))
write_tab(mcse, "c4_05_pool_mcse.csv")

# Earlier design values for the same outcomes (read-only)
k1 <- read.csv(fs::path(C1_TAB_DIR, "07_k_needed.csv"))
k2 <- read.csv(fs::path(C2_TAB_DIR, "c2_04_intervention_design.csv"))
write_tab(k1, "c4_05_cycle1_k_needed_copy.csv")
write_tab(k2, "c4_05_cycle2_design_copy.csv")

# (c) Burn-in after a restart with k points (C4-M4) --------------------------------
# With k points and many runs each, the variance deficit at horizon h is
# ICC(h) / k. T(k, eps) = year after which the fitted ICC(h) / k stays
# <= eps; ICC(h) = 1 - w(h) from the variance fit of c4_04.
burn <- bind_rows(parallel::mclapply(c("prev", "i.prev.dx.B", "num",
  "incid_rate", "dx_frac", "gono_prev", "chla_prev", "syph_prev"),
  mc.cores = N_CORES, function(v) {
    ic <- icc |> filter(var == v, functional == "value")
    fv <- fit_var_relax_c3(ic$h, ic$w_ratio)
    bind_rows(lapply(c(1, 2, 4, 8, 16, 32), function(k) {
      tibble(var = v, k = k, eps = c(0.05, 0.1),
        T = vapply(c(0.05, 0.1), function(e) {
          t_from_fit(function(t) (1 - fv$fn(t)) / k, e)
        }, numeric(1)))
    }))
  }))
write_tab(burn, "c4_05_burnin_by_k.csv")

# Figures ----------------------------------------------------------------------
show <- c("prev", "prev.B", "num", "incid_rate", "dx_frac", "supp_frac",
  "prep_cov", "gono_prev", "chla_prev", "syph_prev")
p <- realised |>
  filter(var %in% show, h <= 100) |>
  ggplot(aes(h)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_ribbon(aes(ymin = var_lo, ymax = var_hi), fill = "steelblue",
    alpha = 0.3) +
  geom_line(aes(y = var_ratio, colour = "observed, 256 runs")) +
  geom_line(aes(y = var_expected, colour = "expected from the direct ICC")) +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(ylim = c(0.5, 1.5)) +
  scale_colour_manual(values = c("red", "black")) +
  labs(x = "Years after the restart", y = "Across-run variance / v_pi",
    colour = NULL,
    title = "Spread of 256 runs restarted from the 32-point pool",
    subtitle = "Band: 95% bootstrap over restart points") +
  theme(legend.position = "bottom")
save_fig(p, "c4_05_realised_variance.png", 14, 7)

p <- realised |>
  filter(var %in% show, h <= 100) |>
  ggplot(aes(h)) +
  geom_hline(yintercept = 0) +
  geom_ribbon(aes(ymin = -2 * offset_rms_expected,
    ymax = 2 * offset_rms_expected), fill = "grey80") +
  geom_ribbon(aes(ymin = offset_lo, ymax = offset_hi), fill = "darkorange",
    alpha = 0.3) +
  geom_line(aes(y = offset)) +
  facet_wrap(~var, ncol = 5) +
  labs(x = "Years after the restart", y = "(pool mean - mu_pi) / SD_pi",
    title = "Shared imprint of the 32-point pool on all its runs",
    subtitle = paste0("Grey: +-2 x the expected RMS error of the mean of ",
      "256 runs on 32 points with these counts. Band: 95% point bootstrap."))
save_fig(p, "c4_05_realised_offset.png", 14, 7)

save_session("c4_05")
