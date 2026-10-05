# =============================================================================
# 05_equilibrium_structure.R
# Question : At stationarity, how long is the memory of each variable
#            (ACF, tau_int), and how is the stationary variance of a 20-year
#            run split between variation over time and over runs?
# Inputs   : data/run/restart_assessment/01_annual.rds
# Outputs  : results/tables/05_*.csv, results/figures/05_*.png,
#            data/run/restart_assessment/05_acf.rds
# Method   : METHODS.md M2.6, M2.7; results/05_equilibrium_structure.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/00_config.R")
source("R/E-restart_assessment/utils.R")
set.seed(SEED)

annual <- readRDS(ANNUAL_PATH)
dict <- annual$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
vars <- c(key, state)
# Only the stationary part of the runs is used (EQ_START from step 04)
Y <- lapply(annual$Y[vars], function(y) y[EQ_START:N_YEARS, , drop = FALSE])
n_c <- ncol(Y[[1]])
n_y <- nrow(Y[[1]])

# Summary of pi ----------------------------------------------------------------
pi_sum <- bind_rows(lapply(vars, function(v) {
  y <- as.vector(Y[[v]])
  q <- quantile(y, c(0.025, 0.25, 0.5, 0.75, 0.975))
  tibble(var = v, block = dict$block[match(v, dict$name)], mean = mean(y),
    sd = sd(y), q025 = q[1], q25 = q[2], q50 = q[3], q75 = q[4],
    q975 = q[5], x0 = annual$x0[v],
    x0_z = (annual$x0[v] - mean(y)) / sd(y))
}))
write_tab(pi_sum, "05_pi_summary.csv")

# Pooled ACF and tau_int (M2.6) --------------------------------------------------
# Global mean and variance over all chains; CIs by chain bootstrap using the
# exact per-chain decomposition (acf_parts / acf_from_parts).
acf_res <- parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  parts <- acf_parts(Y[[v]], ACF_MAX_LAG)
  est <- acf_from_parts(parts)
  bm <- chain_boot(n_c, N_BOOT, function(i) {
    r <- acf_from_parts(parts, i)
    g <- tau_geyer(r)
    c(r, g$tau)
  })
  g <- tau_geyer(est)
  list(
    acf = tibble(var = v, lag = 0:ACF_MAX_LAG, rho = est,
      lo = apply(bm[, 1:(ACF_MAX_LAG + 1)], 2, quantile, 0.025),
      hi = apply(bm[, 1:(ACF_MAX_LAG + 1)], 2, quantile, 0.975)),
    tau = tibble(var = v, tau_int = g$tau, truncated_at_max_lag = g$truncated,
      lo = quantile(bm[, ncol(bm)], 0.025), hi = quantile(bm[, ncol(bm)], 0.975))
  )
})
acf_tab <- bind_rows(lapply(acf_res, `[[`, "acf"))
tau_tab <- bind_rows(lapply(acf_res, `[[`, "tau")) |>
  mutate(block = dict$block[match(var, dict$name)]) |>
  arrange(desc(tau_int))
write_tab(acf_tab, "05_acf.csv")
write_tab(tau_tab, "05_tau_int.csv")
saveRDS(acf_tab, fs::path(INTER_DIR, "05_acf.rds"))
print(as.data.frame(tau_tab))

# Variance-time curve (M2.7) -------------------------------------------------------
# L Var(M_L) / Var_pi -> tau_int; still rising at the largest L means memory
# longer than the data can window.
vt <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- variance_time(Y[[v]], VT_L_GRID, 1)
  bm <- chain_boot(n_c, 200, function(i) {
    variance_time(Y[[v]][, i], VT_L_GRID, 1)
  })
  ci <- boot_ci(bm)
  tibble(var = v, L = VT_L_GRID, vt = est, lo = ci[, 1], hi = ci[, 2])
}))
write_tab(vt, "05_variance_time.csv")

# Window decomposition at L = WINDOW_L (M2.7) ------------------------------------
# Var_pi = E[S2_L] (seen over time within one run) + Var(M_L) (seen only
# across runs). The identity is exact on the pooled set of windows.
split_frac <- function(y) {
  s <- window_split(y, WINDOW_L, 1)
  c(s["within"] / s["total"], s["between"] / s["total"],
    s["within"] + s["between"] - s["total"])
}
split <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- split_frac(Y[[v]])
  bm <- chain_boot(n_c, N_BOOT, function(i) split_frac(Y[[v]][, i])[1:2])
  ci <- boot_ci(bm)
  s <- window_split(Y[[v]], WINDOW_L, 1)
  tibble(var = v, block = dict$block[match(v, dict$name)],
    var_pi = s["total"], within = s["within"], between = s["between"],
    within_frac = est[1], within_lo = ci[1, 1], within_hi = ci[1, 2],
    between_frac = est[2], between_lo = ci[2, 1], between_hi = ci[2, 2],
    identity_error = est[3])
})) |>
  arrange(desc(between_frac))
write_tab(split, "05_variance_split_L20.csv")
cat("Max |identity error|:", max(abs(split$identity_error)), "\n")

# Reference curves for step 06 -----------------------------------------------------
# rho(h)^2 is a lower bound on ICC(h); rho(2h) is exact only for reversible
# processes and is kept as a heuristic.
ref_curves <- acf_tab |>
  select(var, lag, rho) |>
  (\(a) {
    bind_rows(lapply(HORIZONS, function(h) {
      a |>
        summarise(
          rho_h2 = rho[lag == h]^2,
          rho_2h = if (2 * h <= ACF_MAX_LAG) rho[lag == 2 * h] else NA,
          .by = var
        ) |>
        mutate(h = h)
    }))
  })()
write_tab(ref_curves, "05_rho_reference.csv")

# Figures ----------------------------------------------------------------------
p <- acf_tab |>
  filter(var %in% key) |>
  ggplot(aes(lag, rho)) +
  geom_hline(yintercept = 0) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "steelblue", alpha = 0.3) +
  geom_line(linewidth = 0.4) +
  facet_wrap(~var, ncol = 5) +
  labs(x = "Lag (years)", y = "Pooled ACF",
    title = paste0("Stationary autocorrelation (years >= ", EQ_START,
      ", global mean)"))
save_fig(p, "05_acf_key.png", 14, 12)

p <- vt |>
  filter(var %in% key) |>
  ggplot(aes(L, vt)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = "steelblue", alpha = 0.3) +
  geom_line() +
  geom_point(size = 0.8) +
  geom_hline(data = filter(tau_tab, var %in% key),
    aes(yintercept = tau_int), linetype = 2, colour = "red") +
  scale_x_log10() +
  facet_wrap(~var, ncol = 5, scales = "free_y") +
  labs(x = "Window length L (years, log)", y = "L Var(M_L) / Var_pi",
    title = "Variance-time curves", subtitle = "Red dashed: tau_int (Geyer)")
save_fig(p, "05_variance_time_key.png", 14, 12)

p <- split |>
  mutate(var = factor(var, rev(var))) |>
  ggplot(aes(between_frac, var, colour = block)) +
  geom_errorbarh(aes(xmin = between_lo, xmax = between_hi), height = 0) +
  geom_point() +
  labs(x = "Share of Var_pi seen only across runs: Var(M_20) / Var_pi",
    y = NULL, colour = NULL,
    title = "20-year runs: share of stationary variance that is between runs")
save_fig(p, "05_variance_split_L20.png", 8, 10)

save_session("05")
