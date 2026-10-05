# =============================================================================
# c3_04_cold_start.R
# Question : After the production cold start, how many years until the
#            cross-run distribution has the stationary mean and variance
#            (T_cold)? Is the 70-year burn-in enough, and how large is the
#            residual bias at year 70 against the Monte Carlo error of the
#            planned run counts? How does this compare with the restart from
#            x0 (cycle 1)?
# Inputs   : data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            results/tables/04_t_full.csv (cycle 1, read-only)
# Outputs  : cycle3/results/tables/c3_04_*.csv, figures/c3_04_*.png,
#            data/run/restart_assessment/cycle3/c3_04_curves.rds
# Method   : c3_METHODS.md C3-M3, C3-M4; METHODS.md M2.4, M2.5;
#            results/c3_04_cold_start.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

cold <- readRDS(COLD_ANNUAL_PATH)
Y <- cold$Y
dict <- cold$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
proj <- dict$name[dict$block == "project" & !grepl("^cml_incid", dict$name)]
vars <- c(key, state, proj)
n_c <- ncol(Y[[1]])
pi_rows <- LATE_START:N_YEARS
fit_t <- FIT_START:LATE_START
d_mcse <- MCSE_FRAC / sqrt(PLANNED_N_C3)
deltas <- c(DELTA_C3, d_mcse)
t_names <- c(paste0("T_var_", EPS_C3), paste0("T_mean_", DELTA_C3),
  paste0("T_mean_mcse_N", PLANNED_N_C3))

# Year-by-year mean offset and variance ratio -----------------------------------
# o(t) = (m(t) - mu_pi) / SD_pi and r(t) = v(t) / v_pi, with 95% chain-
# bootstrap bands (pi recomputed in each replicate). Cold-start chains are
# independent, so r(t) is not 1 - ICC as it was for x0: it measures how
# dispersed the cold-start law is in that direction (C3-M3).
moments_t <- function(y) {
  pm <- pi_moments(y, pi_rows)
  cm <- cross_moments(y)
  c(cm$v / pm$s2, (cm$m - pm$mu) / sqrt(pm$s2), 100 * (cm$m / pm$mu - 1))
}
n <- N_YEARS
curves <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- moments_t(Y[[v]])
  ci <- boot_ci(chain_boot(n_c, N_BOOT, function(i) moments_t(Y[[v]][, i])))
  tibble(var = v, year = cold$years,
    r = est[1:n], r_lo = ci[1:n, 1], r_hi = ci[1:n, 2],
    o = est[n + 1:n], o_lo = ci[n + 1:n, 1], o_hi = ci[n + 1:n, 2],
    pct = est[2 * n + 1:n], pct_lo = ci[2 * n + 1:n, 1],
    pct_hi = ci[2 * n + 1:n, 2])
}))
saveRDS(curves, fs::path(INTER3_DIR, "c3_04_curves.rds"))

# Relaxation fits and tolerance times (C3-M3) --------------------------------------
# T_var(eps) from the fitted r(t) over years FIT_START-300; T_mean(delta)
# from the fitted o(t) over the tail window (offset <= TAIL_LEVEL SD for
# good). delta also takes the MCSE criterion 0.2 / sqrt(N) of the brief
# (M2.6) for each planned N: the burn-in after which the residual bias
# inflates the MSE of an N-run mean by <= 4%. CIs: 200 bootstrap refits.
fit_all <- function(y) {
  ct <- cold_times(y, fit_t, pi_rows, EPS_C3, deltas, at = PROD_BURNIN)
  c(ct$t_var, ct$t_mean, ct$o_fit, ct$t_tail)
}
fits <- parallel::mclapply(setNames(vars, vars), mc.cores = N_CORES,
  function(v) {
    f <- cold_times(Y[[v]], fit_t, pi_rows, EPS_C3, deltas, at = PROD_BURNIN)
    bm <- do.call(rbind, lapply(seq_len(N_BOOT_FIT), function(b) {
      fit_all(Y[[v]][, sample.int(n_c, n_c, replace = TRUE)])
    }))
    list(f = f, ci = boot_ci(bm))
  })
k_t <- length(t_names)
t_cold <- bind_rows(lapply(vars, function(v) {
  f <- fits[[v]]
  tibble(
    var = v, block = dict$block[match(v, dict$name)],
    var_model = f$f$fv$model, var_c1 = f$f$fv$coef[1],
    var_tau1 = f$f$fv$coef[2], var_tau2 = f$f$fv$coef[4],
    mean_model = f$f$fm$model, mean_tau1 = f$f$fm$coef[2],
    mean_tau2 = if (f$f$fm$model == "2exp") f$f$fm$coef[4] else NA_real_,
    tail_start = f$f$t_tail,
    stat = t_names, est = c(f$f$t_var, f$f$t_mean),
    lo = f$ci[1:k_t, 1], hi = f$ci[1:k_t, 2]
  )
}))
write_tab(t_cold, "c3_04_t_cold.csv")
t_wide <- t_cold |>
  mutate(txt = sprintf("%.0f [%.0f, %.0f]", est, lo, hi)) |>
  select(var, block, var_model, mean_model, mean_tau1, tail_start, stat, txt) |>
  tidyr::pivot_wider(names_from = stat, values_from = txt)
write_tab(t_wide, "c3_04_t_cold_wide.csv")

# Residual bias at the production burn-in (C3-M4) -----------------------------------
# b(70) in SD_pi units, empirical (cross-chain mean at year 70) and fitted,
# and relative to the Monte Carlo error of an N-run mean: b / MCSE =
# b * sqrt(N) (SD units). The brief's criterion is |b| <= 0.2 MCSE.
bias70 <- bind_rows(lapply(vars, function(v) {
  cv <- filter(curves, var == v, year == PROD_BURNIN)
  f <- fits[[v]]
  j <- k_t + 1 # position of o_fit(70) in the bootstrap matrix
  tibble(
    var = v, block = dict$block[match(v, dict$name)],
    o70 = cv$o, o70_lo = cv$o_lo, o70_hi = cv$o_hi,
    pct70 = cv$pct, pct70_lo = cv$pct_lo, pct70_hi = cv$pct_hi,
    r70 = cv$r, r70_lo = cv$r_lo, r70_hi = cv$r_hi,
    o70_fit = f$f$o_fit, o70_fit_lo = f$ci[j, 1], o70_fit_hi = f$ci[j, 2]
  ) |>
    bind_cols(as_tibble(setNames(as.list(abs(cv$o) * sqrt(PLANNED_N_C3)),
      paste0("b_over_mcse_N", PLANNED_N_C3))))
}))
write_tab(bias70, "c3_04_bias70.csv")

# 10-year blocks: a model-free view of the approach to pi ---------------------------
blocks <- curves |>
  mutate(block10 = 10 * ((year - 1) %/% 10) + 5) |>
  filter(year <= 300) |>
  summarise(o = mean(o), r = mean(r), .by = c(var, block10))
write_tab(blocks, "c3_04_block10.csv")

# Multivariate view: whitened state and energy distance (M2.4) ----------------------
wv <- c(key, state)
wh <- whiten(Y, wv, pi_rows, PCA_VAR)
cat("PCs kept:", wh$n_comp, "explaining", round(wh$var_explained, 3), "\n")
D <- rowMeans(energy_trajectory(wh$Z, cold$years, REF_YEARS, N_SPLITS))
null_q <- quantile(D[pi_rows], c(0.5, 0.95, 1))
yrs_rep <- c(1, 10, 20, 30, 50, 70, 100, 120, 150, 200)
write_tab(tibble(year = cold$years, D = D), "c3_04_energy_distance.csv")
write_tab(tibble(n_comp = wh$n_comp, var_explained = wh$var_explained,
  null_median = null_q[1], null_q95 = null_q[2], null_max = null_q[3],
  !!!setNames(as.list(D[yrs_rep]), paste0("D_year", yrs_rep))),
  "c3_04_energy_summary.csv")
# Year after which the 5-year running mean of D stays below the null
# maximum and the null 95% quantile (a detection rule, reported only; the
# tolerance times above are the validated estimates, cycle 1 M2.5)
Ds <- as.vector(stats::filter(D, rep(1 / SMOOTH_W, SMOOTH_W), sides = 2))
last_over <- function(thr) {
  i <- which(Ds[seq_len(LATE_START - 1)] > thr)
  if (length(i)) max(i) + 1 else 1
}
write_tab(tibble(threshold = c("null max", "null q95"),
  value = null_q[c(3, 2)], year_below = c(last_over(null_q[3]),
    last_over(null_q[2]))), "c3_04_energy_rule.csv")

# Principal components: fit times per whitened direction
pc_names <- paste0("PC", seq_len(wh$n_comp))
pcY <- setNames(lapply(seq_len(wh$n_comp), function(k) wh$Z[, , k]), pc_names)
pc_t <- bind_rows(parallel::mclapply(pc_names, mc.cores = N_CORES,
  function(k) {
    f <- cold_times(pcY[[k]], fit_t, pi_rows, EPS_C3, DELTA_C3)
    bm <- do.call(rbind, lapply(seq_len(N_BOOT_FIT), function(b) {
      ct <- cold_times(pcY[[k]][, sample.int(n_c, n_c, replace = TRUE)],
        fit_t, pi_rows, EPS_C3, DELTA_C3)
      c(ct$t_var, ct$t_mean)
    }))
    ci <- boot_ci(bm)
    tibble(pc = k, mean_tau1 = f$fm$coef[2], tail_start = f$t_tail,
      stat = c(paste0("T_var_", EPS_C3), paste0("T_mean_", DELTA_C3)),
      est = c(f$t_var, f$t_mean), lo = ci[, 1], hi = ci[, 2])
  }))
write_tab(pc_t, "c3_04_pc_t_cold.csv")
S <- vapply(wv, function(v) {
  pm <- pi_moments(Y[[v]], pi_rows)
  as.vector((Y[[v]][pi_rows, ] - pm$mu) / sqrt(pm$s2))
}, numeric(length(pi_rows) * n_c))
loads <- cor(S, matrix(wh$Z[pi_rows, , ], ncol = wh$n_comp))
colnames(loads) <- pc_names
write_tab(data.frame(var = wv, loads), "c3_04_pc_loadings.csv", 3)
rm(S)

# Comparison with the restart from x0 (cycle 1, step 04) ----------------------------
# Same tolerances; x0 times are relative to pi_x0, cold-start times to
# pi_cold (the two laws differ, c3_03).
t_x0 <- read.csv(fs::path(C1_TAB_DIR, "04_t_full.csv")) |>
  filter(stat %in% c("T_var_0.1", "T_var_0.2", "T_mean_0.1", "T_mean_0.2")) |>
  transmute(var, stat, x0 = sprintf("%.0f [%.0f, %.0f]", est, lo, hi),
    x0_est = est)
cmp <- t_cold |>
  filter(stat %in% c("T_var_0.1", "T_var_0.2", "T_mean_0.1", "T_mean_0.2")) |>
  transmute(var, block, stat, cold = sprintf("%.0f [%.0f, %.0f]", est, lo, hi),
    cold_est = est) |>
  inner_join(t_x0, by = c("var", "stat"))
write_tab(cmp, "c3_04_compare_x0.csv")

# EQ_START for the equilibrium analyses of the cold-start runs (c3_06) ---------------
# Rule of cycle 1: the slowest fitted time over key and state variables at
# the 10% / 0.1 SD tolerances, rounded up to a multiple of 10, + 50 years.
slow <- t_cold |>
  filter(block %in% c("key", "state"), stat %in% c("T_var_0.1", "T_mean_0.1"),
    is.finite(est)) |>
  arrange(desc(est))
eq_rule <- 10 * ceiling(max(slow$est) / 10) + 50
write_tab(tibble(slowest_var = slow$var[1], slowest_stat = slow$stat[1],
  slowest_T = slow$est[1], eq_start_rule = eq_rule), "c3_04_eq_start.csv")
cat("EQ_START rule:", eq_rule, "(slowest:", slow$var[1], slow$stat[1],
  slow$est[1], ")\n")

# Figures ----------------------------------------------------------------------
fitted_curves <- bind_rows(lapply(vars, function(v) {
  tt <- seq(FIT_START, 300, 0.5)
  f <- fits[[v]]$f
  tibble(var = v, year = tt, r_fit = f$fv$fn(tt),
    o_fit = ifelse(tt >= f$t_tail, f$fm$fn(tt), NA_real_))
}))
plot_vars <- key
p <- curves |>
  filter(var %in% plot_vars, year <= 200) |>
  ggplot(aes(year)) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_hline(yintercept = c(-0.1, 0.1), linetype = 3) +
  geom_ribbon(aes(ymin = o_lo, ymax = o_hi), fill = "darkorange", alpha = 0.3) +
  geom_line(aes(y = o), linewidth = 0.3) +
  geom_line(data = filter(fitted_curves, var %in% plot_vars, year <= 200),
    aes(y = o_fit), colour = "red", na.rm = TRUE) +
  geom_vline(xintercept = PROD_BURNIN, colour = "steelblue", linetype = 2) +
  facet_wrap(~var, ncol = 5, scales = "free_y") +
  coord_cartesian(ylim = c(-3, 3)) +
  labs(x = "Years after the cold start", y = "(m(t) - mu_pi) / SD_pi",
    title = "Offset of the cross-run mean from the stationary mean, cold start",
    subtitle = paste0("Band: 95% chain bootstrap. Red: tail fit. Dotted: ",
      "+-0.1 SD. Blue: year 70 (production burn-in). Clipped at +-3 SD."))
save_fig(p, "c3_04_mean_offset_key.png", 14, 13)

p <- curves |>
  filter(var %in% plot_vars, year <= 200) |>
  ggplot(aes(year)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_hline(yintercept = c(0.9, 1.1), linetype = 3) +
  geom_ribbon(aes(ymin = r_lo, ymax = r_hi), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = r), linewidth = 0.3) +
  geom_line(data = filter(fitted_curves, var %in% plot_vars, year <= 200),
    aes(y = r_fit), colour = "red") +
  geom_vline(xintercept = PROD_BURNIN, colour = "steelblue", linetype = 2) +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(ylim = c(0, 1.6)) +
  labs(x = "Years after the cold start", y = "v(t) / v_pi",
    title = "Variance across runs relative to the stationary variance, cold start",
    subtitle = "Band: 95% chain bootstrap. Red: relaxation fit. Blue: year 70.")
save_fig(p, "c3_04_var_ratio_key.png", 14, 13)

p <- curves |>
  filter(var %in% plot_vars, year <= 300) |>
  ggplot(aes(year, abs(o))) +
  geom_hline(yintercept = c(0.1, 0.2), linetype = 3) +
  geom_hline(yintercept = 1 / sqrt(n_c), colour = "grey50") +
  geom_line(linewidth = 0.3) +
  geom_line(data = filter(fitted_curves, var %in% plot_vars),
    aes(y = abs(o_fit)), colour = "red", na.rm = TRUE) +
  scale_y_log10() +
  coord_cartesian(ylim = c(1e-3, 30)) +
  facet_wrap(~var, ncol = 5) +
  labs(x = "Years after the cold start", y = "|offset| (SD_pi, log scale)",
    title = "Tail of the mean relaxation after the cold start",
    subtitle = paste0("Red: tail fit. Grey: standard error of a 256-chain ",
      "mean (1/16 SD). Dotted: 0.1 and 0.2 SD."))
save_fig(p, "c3_04_offset_log_key.png", 14, 13)

p <- ggplot(tibble(year = cold$years, D = D), aes(year, D)) +
  annotate("rect", xmin = LATE_START, xmax = N_YEARS, ymin = -Inf, ymax = Inf,
    alpha = 0.1) +
  geom_hline(yintercept = null_q, linetype = c(3, 2, 1), colour = "grey40") +
  geom_vline(xintercept = PROD_BURNIN, colour = "steelblue", linetype = 2) +
  geom_line(linewidth = 0.3) +
  scale_y_log10() +
  labs(x = "Years after the cold start", y = "Energy distance (log scale)",
    title = paste0("Distance of the state distribution at year t to pi (",
      wh$n_comp, " whitened PCs), cold start"),
    subtitle = "Shaded: null period. Lines: null median, 95% quantile, max.")
save_fig(p, "c3_04_energy_distance.png", 10, 5)

save_session("c3_04")
