# =============================================================================
# c5_05_relaxation.R
# Question : After a sustained change from the restart (S4, 10% fewer acts),
#            how long until the runs reach the new equilibrium, what share of
#            the long-run effect is present after 10, 20, 50 years, and does
#            the effect heterogeneity between restart points fade with the
#            horizon?
# Inputs   : data/run/restart_assessment/cycle5/c5_01_annual_long.rds
# Outputs  : cycle5/results/tables/c5_05_*.csv, figures/c5_05_*.png
# Method   : c5_METHODS.md C5-M5; results/c5_05_relaxation.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle5/c5_config.R")
source("R/E-restart_assessment/cycle5/c5_utils.R")
set.seed(SEED)

lg <- readRDS(LONG_ANNUAL_PATH)
vars <- c("prev", "prev.B", "prev.H", "prev.W", "incid_rate", "num", "dx_frac",
  "gono_prev", "chla_prev", "syph_prev")
hs <- seq_len(LONG_YEARS)
eq <- S4_EQ_YEARS

# Paired effect trajectory Delta(h), by year ----------------------------------------------
eff_h <- function(v, ga, ra, g0, r0) {
  t(vapply(hs, function(h) {
    pe <- paired_effect(point_summary(lg$s4$Y[[v]][h, ra], ga,
      lg$base$Y[[v]][h, r0], g0))
    c(delta = pe$delta, se = pe$se, s2 = pe$s2_delta, s2_lo = pe$s2_lo,
      s2_hi = pe$s2_hi, p_het = pe$p_het, icc_delta = pe$icc_delta)
  }, numeric(7)))
}
all_a <- seq_along(lg$s4$point)
all_0 <- seq_along(lg$base$point)

# Relaxation of the effect toward its long-run value (C5-M5) -------------------------------
# Delta_inf = mean paired effect over years 101-150 (checked for drift);
# o(h) = (Delta(h) - Delta_inf) / SD_pi of the baseline, fitted with the
# cycle 3 mean-relaxation models; T(delta) from the fit (cycle 1 M2.5).
relax_one <- function(v, E) {
  d <- E[, "delta"]
  d_inf <- mean(d[eq])
  sd_pi <- sqrt(lg$pi_base[[v]]$s2)
  o <- (d - d_inf) / sd_pi
  fm <- fit_mean_relax_c3(hs, o)
  c(d_inf = d_inf, sd_pi = sd_pi, drift_per_50y = ols_slope(eq, d[eq]) * 50,
    T01 = t_from_fit(fm$fn, 0.1), T02 = t_from_fit(fm$fn, 0.2),
    share10 = d[10] / d_inf, share20 = d[20] / d_inf, share50 = d[50] / d_inf,
    share10_fit = 1 - fm$fn(10) * sd_pi / d_inf,
    model = match(fm$model, c("1exp", "2exp", "damped_cos")))
}

res <- bind_rows(lapply(vars, function(v) {
  E <- eff_h(v, lg$s4$point, all_a, lg$base$point, all_0)
  est <- relax_one(v, E)
  # bootstrap over restart points: each draw keeps all runs of a point, in both arms
  pts <- sort(unique(lg$base$point))
  ia <- split(all_a, factor(lg$s4$point, pts))
  i0 <- split(all_0, factor(lg$base$point, pts))
  bt <- t(vapply(seq_len(200), function(b) {
    dr <- sample(length(pts), replace = TRUE)
    ra <- unlist(ia[dr]); r0 <- unlist(i0[dr])
    Eb <- eff_h(v, rep(seq_along(dr), lengths(ia[dr])), ra,
      rep(seq_along(dr), lengths(i0[dr])), r0)
    relax_one(v, Eb)
  }, numeric(length(est))))
  ci <- apply(bt, 2, quantile, c(0.025, 0.975), na.rm = TRUE)
  tibble(var = v, stat = names(est), est = est, lo = ci[1, ], hi = ci[2, ])
}))
res$est[res$stat == "model"] <- res$est[res$stat == "model"]
write_tab(res, "c5_05_relaxation.csv")
print(as.data.frame(res |> filter(stat %in% c("d_inf", "drift_per_50y", "T01", "T02",
  "share10", "share20", "share50", "model"))), digits = 3)

# Effect heterogeneity by horizon (does it fade?) -----------------------------------------
het <- bind_rows(lapply(vars, function(v) {
  E <- eff_h(v, lg$s4$point, all_a, lg$base$point, all_0)
  sd_pi <- sqrt(lg$pi_base[[v]]$s2)
  tibble(var = v, year = hs, delta_sd = E[, "delta"] / sd_pi,
    se_sd = E[, "se"] / sd_pi,
    sd_delta_sd = sqrt(pmax(E[, "s2"], 0)) / sd_pi,
    sd_hi_sd = sqrt(pmax(E[, "s2_hi"], 0)) / sd_pi,
    p_het = E[, "p_het"], icc_delta = E[, "icc_delta"])
}))
write_tab(het, "c5_05_heterogeneity_by_year.csv")
het_sum <- het |>
  mutate(period = cut(year, c(0, 5, 10, 20, 50, 100, 150),
    labels = c("1-5", "6-10", "11-20", "21-50", "51-100", "101-150"))) |>
  summarise(mean_sd_delta_sd = mean(sd_delta_sd), mean_icc_delta = mean(icc_delta),
    share_p05 = mean(p_het < 0.05), .by = c(var, period))
write_tab(het_sum, "c5_05_heterogeneity_summary.csv")
print(as.data.frame(het_sum |> filter(var %in% c("prev", "incid_rate", "num", "gono_prev"))),
  digits = 3)

# Figures --------------------------------------------------------------------------------
p <- ggplot(het |> filter(var %in% c("prev", "incid_rate", "num", "dx_frac",
  "gono_prev", "syph_prev")), aes(year, delta_sd)) +
  geom_ribbon(aes(ymin = delta_sd - 2 * se_sd, ymax = delta_sd + 2 * se_sd), alpha = 0.3) +
  geom_line() + geom_hline(yintercept = 0, colour = "grey50") +
  facet_wrap(~var, scales = "free_y") +
  labs(x = "Years after the change (the restart)", y = "Effect of S4, in SD_pi of the baseline",
    title = "S4: 10% fewer acts. Paired effect against the baseline runs, +- 2 SE")
save_fig(p, "c5_05_effect_trajectory.png")

p <- ggplot(het |> filter(var %in% c("prev", "incid_rate", "num", "gono_prev")),
  aes(year, sd_delta_sd)) +
  geom_line(aes(y = sd_hi_sd), colour = "grey60", linetype = 2) + geom_line() +
  facet_wrap(~var) + scale_x_log10() +
  labs(x = "Years after the change (log scale)",
    y = "SD of the effect between restart points (SD_pi units)",
    title = "Does the effect depend less on the restart state as time goes on?",
    subtitle = "Solid: estimate; dashed: upper 95% limit")
save_fig(p, "c5_05_heterogeneity_by_year.png")

saveRDS(list(res = res, het = het), fs::path(INTER5_DIR, "c5_05_relaxation.rds"))
save_session("c5_05")
