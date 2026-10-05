# =============================================================================
# 04_relaxation_from_x0.R
# Question : Starting every run from the single restart state x0, how long
#            until the cross-run distribution has the full stationary variance
#            (and mean)? For annual values, and for 20-year research windows
#            started after a post-restart burn-in of B years.
# Inputs   : data/run/restart_assessment/01_annual.rds
# Outputs  : results/tables/04_*.csv, results/figures/04_*.png,
#            data/run/restart_assessment/04_icc_x0.rds
# Method   : METHODS.md M2.1, M2.2, M2.4, M2.5; results/04_relaxation_from_x0.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/00_config.R")
source("R/E-restart_assessment/utils.R")
set.seed(SEED)

annual <- readRDS(ANNUAL_PATH)
Y <- annual$Y
dict <- annual$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
vars <- c(key, state)
n_c <- ncol(Y[[1]])
pi_rows <- LATE_START:N_YEARS
fit_t <- 1:LATE_START
N_BOOT_FIT <- 200 # refits are slower than moments; 200 is enough for T CIs

# Year-by-year variance ratio and mean offset with bootstrap bands -------------
# r(t) = v(t) / v_pi is the share of the stationary variance present t years
# after the common restart; 1 - r(t) is ICC_x0(t) for this particular x0
# (M2.2). o(t) is the offset of the cross-run mean from the pi mean in SD_pi
# units, i.e. how atypical x0 still is t years later.
moments_x0 <- function(y) {
  pm <- pi_moments(y, pi_rows)
  cm <- cross_moments(y)
  c(cm$v / pm$s2, (cm$m - pm$mu) / sqrt(pm$s2))
}
curves <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- moments_x0(Y[[v]])
  bm <- chain_boot(n_c, N_BOOT, function(i) moments_x0(Y[[v]][, i]))
  ci <- boot_ci(bm)
  n <- N_YEARS
  tibble(
    var = v, year = annual$years,
    r = est[1:n], r_lo = ci[1:n, 1], r_hi = ci[1:n, 2],
    o = est[n + 1:n], o_lo = ci[n + 1:n, 1], o_hi = ci[n + 1:n, 2]
  )
}))
icc_x0 <- curves |>
  filter(year %in% HORIZONS) |>
  transmute(var, h = year, icc = 1 - r, icc_lo = 1 - r_hi, icc_hi = 1 - r_lo)
saveRDS(curves, fs::path(INTER_DIR, "04_curves_x0.rds"))
write_tab(icc_x0, "04_icc_x0.csv")

# Relaxation fits and tolerance times (M2.5) -----------------------------------
# T_var(eps): fitted variance deficit 1 - r(t) stays below eps.
# T_mean(delta): fitted |o(t)| stays below delta.
# Detection rules on noisy yearly statistics are unreliable here (see
# 02_validate_methods.md), so times come from the fitted curves and their CIs
# from refitting on chain bootstraps.
fit_times <- function(y) {
  pm <- pi_moments(y, pi_rows)
  cm <- cross_moments(y[fit_t, , drop = FALSE])
  fv <- fit_var_relax(fit_t, cm$v / pm$s2)
  fm <- fit_mean_relax(fit_t, (cm$m - pm$mu) / sqrt(pm$s2))
  tv <- vapply(VAR_EPS, function(e) t_from_fit(function(t) 1 - fv$fn(t), e),
    numeric(1))
  tm <- vapply(c(0.1, 0.2), function(d) t_from_fit(fm$fn, d), numeric(1))
  list(
    times = c(tv, tm),
    fv = fv, fm = fm
  )
}
t_names <- c(paste0("T_var_", VAR_EPS), "T_mean_0.1", "T_mean_0.2")
fits <- parallel::mclapply(setNames(vars, vars), mc.cores = N_CORES,
  function(v) {
  f <- fit_times(Y[[v]])
  bm <- chain_boot(n_c, N_BOOT_FIT, function(i) fit_times(Y[[v]][, i])$times)
  ci <- boot_ci(bm)
  list(f = f, ci = ci)
})
t_full <- bind_rows(lapply(vars, function(v) {
  f <- fits[[v]]
  tibble(
    var = v, block = dict$block[match(v, dict$name)],
    var_model = f$f$fv$model,
    var_c1 = f$f$fv$coef[1], var_tau1 = f$f$fv$coef[2],
    var_c2 = f$f$fv$coef[3], var_tau2 = f$f$fv$coef[4],
    mean_model = f$f$fm$model,
    o_year1 = curves$o[curves$var == v & curves$year == 1],
    stat = t_names, est = f$f$times, lo = f$ci[, 1], hi = f$ci[, 2]
  )
}))
write_tab(t_full, "04_t_full.csv")

t_wide <- t_full |>
  mutate(txt = sprintf("%.0f [%.0f, %.0f]", est, lo, hi)) |>
  select(var, block, var_model, var_tau1, var_tau2, o_year1, stat, txt) |>
  tidyr::pivot_wider(names_from = stat, values_from = txt)
write_tab(t_wide, "04_t_full_wide.csv")
print(as.data.frame(t_wide))

# Fitted curves for the figures
fitted_curves <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  tt <- seq(0.5, 300, 0.5)
  tibble(var = v, year = tt, r_fit = fits[[v]]$f$fv$fn(tt),
    o_fit = fits[[v]]$f$fm$fn(tt))
}))

# Research windows after a post-restart burn-in (M2.7) -------------------------
# A research run of L years after a burn-in of B years covers years
# B + 1 ... B + L after restart. For each B, compare across chains:
#   - Var(M_L(B)) / Var_pi(M_L): share of the stationary between-run variance
#     of the window mean;
#   - mean S2_L(B) / E_pi[S2_L]: share of the stationary within-run variance;
#   - offset of the mean of M_L(B) in SD_pi(M_L) units.
# The pi references use all non-overlapping windows starting at LATE_START,
# with the global mean.
win_ref <- function(y) {
  ws <- window_stats(y, WINDOW_L, LATE_START)
  mu <- mean(y[LATE_START:(LATE_START + nrow(ws$M) * WINDOW_L - 1), ])
  c(mu = mu, vM = mean((ws$M - mu)^2), S2 = mean(ws$S2))
}
win_x0 <- function(y) {
  ref <- win_ref(y)
  cs <- rbind(0, apply(y, 2, cumsum))
  out <- vapply(BURNIN_GRID, function(B) {
    M <- (cs[B + WINDOW_L + 1, ] - cs[B + 1, ]) / WINDOW_L
    blk <- y[B + seq_len(WINDOW_L), , drop = FALSE]
    S2 <- colMeans(sweep(blk, 2, M)^2)
    c(var(M) / ref["vM"], mean(S2) / ref["S2"],
      (mean(M) - ref["mu"]) / sqrt(ref["vM"]))
  }, numeric(3))
  as.vector(t(out))
}
nb <- length(BURNIN_GRID)
win <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- win_x0(Y[[v]])
  bm <- chain_boot(n_c, N_BOOT, function(i) win_x0(Y[[v]][, i]))
  ci <- boot_ci(bm)
  tibble(
    var = v, B = BURNIN_GRID,
    between = est[1:nb], between_lo = ci[1:nb, 1], between_hi = ci[1:nb, 2],
    within = est[nb + 1:nb], within_lo = ci[nb + 1:nb, 1],
    within_hi = ci[nb + 1:nb, 2],
    offset = est[2 * nb + 1:nb], offset_lo = ci[2 * nb + 1:nb, 1],
    offset_hi = ci[2 * nb + 1:nb, 2]
  )
}))
write_tab(win, "04_window_burnin.csv")
saveRDS(win, fs::path(INTER_DIR, "04_window_burnin.rds"))

# Burn-in needed for the window quantities (M2.5, M2.7): as for annual values,
# "first B from which the ratio stays above 1 - eps" is unreliable on noisy
# point estimates, so the between-run ratio is fitted as a function of B with
# the same relaxation models and B(eps) is read from the fit. CIs by refitting
# on chain bootstraps of the window statistics.
win_burnin_fit <- function(y) {
  est <- win_x0(y)[1:nb]
  f <- fit_var_relax(BURNIN_GRID, est)
  vapply(VAR_EPS, function(e) t_from_fit(function(t) 1 - f$fn(t), e),
    numeric(1))
}
win_t <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES, function(v) {
  est <- win_burnin_fit(Y[[v]])
  bm <- chain_boot(n_c, N_BOOT_FIT, function(i) win_burnin_fit(Y[[v]][, i]))
  ci <- boot_ci(bm)
  tibble(var = v, stat = paste0("B_between_", VAR_EPS), est = est,
    lo = ci[, 1], hi = ci[, 2])
}))
write_tab(win_t, "04_window_burnin_needed.csv")
print(as.data.frame(win_t))

# Multivariate view: whitened state and energy distance (M2.4) -----------------
# Standardise key + state variables by pi, whiten with a PCA on the pi
# covariance (keep PCA_VAR of the variance), then (a) the energy distance
# between half the chains at year t and the other half at REF_YEARS, and
# (b) the variance ratio of each principal component, which finds the
# slowest direction of the state even when no single variable shows it.
wh <- whiten(Y, vars, pi_rows, PCA_VAR)
cat("PCs kept:", wh$n_comp, "explaining", round(wh$var_explained, 3), "\n")
D <- energy_trajectory(wh$Z, annual$years, REF_YEARS, N_SPLITS)
Dm <- rowMeans(D)
null_q <- quantile(Dm[pi_rows], c(0.5, 0.95, 1))
energy <- tibble(year = annual$years, D = Dm)
write_tab(energy, "04_energy_distance.csv")
write_tab(tibble(n_comp = wh$n_comp, var_explained = wh$var_explained,
  null_median = null_q[1], null_q95 = null_q[2], null_max = null_q[3],
  D_year1 = Dm[1], D_year10 = Dm[10], D_year20 = Dm[20], D_year50 = Dm[50],
  D_year70 = Dm[70], D_year100 = Dm[100]), "04_energy_summary.csv")

pc_names <- paste0("PC", seq_len(wh$n_comp))
pcY <- setNames(lapply(seq_len(wh$n_comp), function(k) wh$Z[, , k]),
  pc_names)
pc_t <- bind_rows(parallel::mclapply(pc_names, mc.cores = N_CORES,
  function(k) {
  f <- fit_times(pcY[[k]])
  bm <- chain_boot(n_c, N_BOOT_FIT, function(i) fit_times(pcY[[k]][, i])$times)
  ci <- boot_ci(bm)
  tibble(pc = k, var_model = f$fv$model, tau1 = f$fv$coef[2],
    tau2 = f$fv$coef[4], stat = t_names, est = f$times, lo = ci[, 1],
    hi = ci[, 2])
}))
write_tab(pc_t, "04_pc_t_full.csv")
# loadings of the PCs on the standardised variables, for interpretation
S <- vapply(vars, function(v) {
  pm <- pi_moments(Y[[v]], pi_rows)
  as.vector((Y[[v]][pi_rows, ] - pm$mu) / sqrt(pm$s2))
}, numeric(length(pi_rows) * n_c))
loads <- cor(S, matrix(wh$Z[pi_rows, , ], ncol = wh$n_comp))
colnames(loads) <- pc_names
write_tab(data.frame(var = vars, loads), "04_pc_loadings.csv", 3)
rm(S)

pc_curves <- bind_rows(lapply(pc_names, function(k) {
  cm <- cross_moments(pcY[[k]])
  tibble(pc = k, year = annual$years, r = cm$v / pi_moments(pcY[[k]],
    pi_rows)$s2, o = cm$m / sqrt(pi_moments(pcY[[k]], pi_rows)$s2))
}))
saveRDS(list(fitted_curves = fitted_curves, pc_curves = pc_curves),
  fs::path(INTER_DIR, "04_fitted_curves.rds"))

# Figures ----------------------------------------------------------------------
plot_vars <- key
p <- curves |>
  filter(var %in% plot_vars, year <= 150) |>
  ggplot(aes(year)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_hline(yintercept = 0.9, linetype = 3) +
  geom_ribbon(aes(ymin = r_lo, ymax = r_hi), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = r), linewidth = 0.3) +
  geom_line(data = filter(fitted_curves, var %in% plot_vars, year <= 150),
    aes(y = r_fit), colour = "red") +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(ylim = c(0, 1.4)) +
  labs(x = "Years after restart", y = "v(t) / v_pi",
    title = "Share of the stationary variance t years after the single restart",
    subtitle = "Band: 95% chain bootstrap. Red: relaxation fit.")
save_fig(p, "04_var_ratio_key.png", 14, 13)

p <- curves |>
  filter(var %in% plot_vars, year <= 150) |>
  ggplot(aes(year)) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_ribbon(aes(ymin = o_lo, ymax = o_hi), fill = "darkorange",
    alpha = 0.3) +
  geom_line(aes(y = o), linewidth = 0.3) +
  geom_line(data = filter(fitted_curves, var %in% plot_vars, year <= 150),
    aes(y = o_fit), colour = "red") +
  facet_wrap(~var, ncol = 5, scales = "free_y") +
  labs(x = "Years after restart", y = "(m(t) - mu_pi) / SD_pi",
    title = "Offset of the cross-run mean from the stationary mean",
    subtitle = "Band: 95% chain bootstrap. Red: relaxation fit.")
save_fig(p, "04_mean_offset_key.png", 14, 13)

p <- win |>
  filter(var %in% plot_vars) |>
  tidyr::pivot_longer(c(between, within), names_to = "component") |>
  mutate(
    lo = ifelse(component == "between", between_lo, within_lo),
    hi = ifelse(component == "between", between_hi, within_hi)
  ) |>
  ggplot(aes(B, value, colour = component, fill = component)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.2, colour = NA) +
  geom_line() +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(xlim = c(0, 150), ylim = c(0, 1.5)) +
  labs(x = "Post-restart burn-in B (years)",
    y = "Share of the stationary value",
    title = paste0("20-year research windows after a burn-in of B years, ",
      "single restart point"),
    subtitle = paste0("between = Var(window mean) / Var_pi(window mean); ",
      "within = E[within-window variance] / E_pi[...]"))
save_fig(p, "04_window_burnin_key.png", 14, 13)

p <- ggplot(energy, aes(year, D)) +
  annotate("rect", xmin = LATE_START, xmax = N_YEARS, ymin = -Inf, ymax = Inf,
    alpha = 0.1) +
  geom_hline(yintercept = null_q[1], linetype = 3, colour = "grey40") +
  geom_hline(yintercept = null_q[2], linetype = 2, colour = "grey40") +
  geom_hline(yintercept = null_q[3], linetype = 1, colour = "grey40") +
  geom_line(linewidth = 0.3) +
  scale_y_log10() +
  labs(x = "Years after restart", y = "Energy distance (log scale)",
    title = paste0("Multivariate distance of the state distribution at year t",
      " to pi (", wh$n_comp, " whitened PCs)"),
    subtitle = paste0("Shaded: null period. Lines: null median, 95% ",
      "quantile and max."))
save_fig(p, "04_energy_distance.png", 10, 5)
save_fig(p + coord_cartesian(xlim = c(0, 150)), "04_energy_distance_150.png",
  10, 5)

p <- pc_curves |>
  filter(year <= 150) |>
  mutate(pc = factor(pc, pc_names)) |>
  ggplot(aes(year, r)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_line(linewidth = 0.3) +
  facet_wrap(~pc) +
  coord_cartesian(ylim = c(0, 1.5)) +
  labs(x = "Years after restart", y = "v(t) / v_pi",
    title = "Variance ratio of each whitened principal component")
save_fig(p, "04_pc_var_ratio.png", 12, 8)

save_session("04")
