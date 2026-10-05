# =============================================================================
# c3_03_same_law.R
# Question : Do the cold-start runs settle into a stationary law, and is it
#            the same law as that of the x0 runs (cycles 1-2), which share
#            the parameter file and the model code? Which of the two matches
#            the calibration targets?
# Inputs   : data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            data/run/restart_assessment/01_annual.rds (cycle 1, read-only),
#            cycle3/results/tables/c3_01_network_coefs.csv
# Outputs  : cycle3/results/tables/c3_03_*.csv, figures/c3_03_*.png
# Method   : c3_METHODS.md C3-M2; METHODS.md M2.2; results/c3_03_same_law.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

cold <- readRDS(COLD_ANNUAL_PATH)
x0 <- readRDS(X0_ANNUAL_PATH)
Yc <- cold$Y
Yx <- add_project_vars(x0$Y)
dict <- cold$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
proj <- intersect(dict$name[dict$block == "project"], names(Yx))
proj <- proj[!grepl("^cml_incid", proj)] # aliases of hiv.incid.*
vars <- c(key, state, proj)
n_c <- ncol(Yc[[1]])
n_x <- ncol(Yx[[1]])
rm(x0)

# Stationarity of the cold-start runs (M2.2) --------------------------------------
# Same drift tests as cycle 1 step 03 (periods 300-600 and 150-600). A flag
# over 150-600 but not 300-600 would be the tail of the cold-start
# relaxation rather than the absence of a stationary law.
drift <- bind_rows(parallel::mclapply(DRIFT_PERIODS, mc.cores = 2,
  function(per) {
    yrs <- per[1]:per[2]
    bind_rows(lapply(c(key, state), function(v) {
      est <- drift_stats(Yc[[v]], yrs)
      bm <- chain_boot(n_c, N_BOOT, function(i) drift_stats(Yc[[v]][, i], yrs))
      ci <- boot_ci(bm)
      tibble(var = v, block = dict$block[match(v, dict$name)],
        period = paste(per, collapse = "-"),
        mean_drift = est[1], mean_lo = ci[1, 1], mean_hi = ci[1, 2],
        var_drift = est[2], var_lo = ci[2, 1], var_hi = ci[2, 2])
    }))
  })) |>
  mutate(
    mean_flag = (mean_lo > 0 | mean_hi < 0) & abs(mean_drift) > MEAN_DRIFT_TOL,
    var_flag = (var_lo > 0 | var_hi < 0) & abs(var_drift) > VAR_DRIFT_TOL,
    flag = mean_flag | var_flag
  )
write_tab(drift, "c3_03_drift.csv")
cat("Drift flags:", sum(drift$flag), "of", nrow(drift), "\n")
print(as.data.frame(filter(drift, flag)))

# Two stationary laws: per variable (C3-M2) ------------------------------------------
# pi_cold and pi_x0 are each estimated from years >= LATE_START of their own
# chains. Statistics from per-chain sums: mean difference in pooled SD_pi
# units, relative difference (%), variance ratio. CIs: independent chain
# bootstraps of the two datasets. p-values: chain permutations between the
# datasets (exact under H0), per variable and global (max-T).
rows <- LATE_START:N_YEARS
n_t <- length(rows)
S <- setNames(lapply(vars, function(v) {
  rbind(chain_sums(Yc[[v]], rows), chain_sums(Yx[[v]], rows))
}), vars)
pt <- perm_test_moments(S, n_c, n_t, N_PERM)
boot_stats <- function(ia, ib) {
  vapply(S, function(Sv) {
    a <- group_moments(Sv[ia, , drop = FALSE], n_t)
    b <- group_moments(Sv[n_c + ib, , drop = FALSE], n_t)
    c(d_mean = unname((a["mu"] - b["mu"]) / sqrt((a["s2"] + b["s2"]) / 2)),
      pct = unname(100 * (a["mu"] / b["mu"] - 1)),
      vr = unname(a["s2"] / b["s2"]))
  }, numeric(3))
}
est <- boot_stats(seq_len(n_c), seq_len(n_x))
bm <- simplify2array(parallel::mclapply(seq_len(N_BOOT), mc.cores = N_CORES,
  function(b) {
    boot_stats(sample.int(n_c, n_c, replace = TRUE),
      sample.int(n_x, n_x, replace = TRUE))
  }))
ci <- apply(bm, c(1, 2), quantile, c(0.025, 0.975))
laws <- tibble(
  var = vars, block = dict$block[match(vars, dict$name)],
  mu_cold = vapply(S, function(Sv) group_moments(Sv[seq_len(n_c), ], n_t)["mu"],
    numeric(1)),
  mu_x0 = vapply(S, function(Sv) group_moments(Sv[-seq_len(n_c), ], n_t)["mu"],
    numeric(1)),
  sd_cold = vapply(S, function(Sv) {
    sqrt(group_moments(Sv[seq_len(n_c), ], n_t)["s2"])
  }, numeric(1)),
  sd_x0 = vapply(S, function(Sv) {
    sqrt(group_moments(Sv[-seq_len(n_c), ], n_t)["s2"])
  }, numeric(1)),
  d_mean = est[1, ], d_mean_lo = ci[1, 1, ], d_mean_hi = ci[2, 1, ],
  pct_diff = est[2, ], pct_lo = ci[1, 2, ], pct_hi = ci[2, 2, ],
  var_ratio = est[3, ], vr_lo = ci[1, 3, ], vr_hi = ci[2, 3, ],
  z_mean = pt$per_var$z_mean, p_mean = pt$per_var$p_mean,
  z_var = pt$per_var$z_var, p_var = pt$per_var$p_var
) |>
  arrange(desc(abs(d_mean)))
write_tab(laws, "c3_03_law_compare.csv")
write_tab(pt$global, "c3_03_law_global.csv")
print(as.data.frame(pt$global))
print(as.data.frame(head(laws, 25)))

# Two stationary laws: the whole state (C3-M2) --------------------------------------
# Key and state variables, standardised by the pooled pi moments and
# whitened (PCA on the pooled pi covariance, PCA_VAR of the variance), at
# cross-sections every ED_YEAR_STEP years from LATE_START. Energy statistic
# between the two datasets; null by chain permutation.
wv <- c(key, state)
Yall <- lapply(setNames(wv, wv), function(v) cbind(Yc[[v]], Yx[[v]]))
wh <- whiten(Yall, wv, rows, PCA_VAR)
yrs <- seq(LATE_START, N_YEARS, by = ED_YEAR_STEP)
in_cold <- rep(c(TRUE, FALSE), c(n_c, n_x))
et <- energy_chain_test(wh$Z[yrs, , , drop = FALSE], in_cold, N_PERM)
# Placebo: two random halves of the cold-start chains, same statistic
half <- sample(rep(c(TRUE, FALSE), length.out = n_c))
Zc <- whiten(lapply(setNames(wv, wv), function(v) Yc[[v]]), wv, rows,
  PCA_VAR)$Z
ep <- energy_chain_test(Zc[yrs, , , drop = FALSE], half, N_PERM)
energy <- tibble(
  comparison = c("cold start vs x0 runs", "placebo: two halves of cold start"),
  n_components = c(wh$n_comp, NA), n_cross_sections = length(yrs),
  energy = c(et$stat, ep$stat),
  null_median = c(median(et$null), median(ep$null)),
  null_q95 = c(quantile(et$null, 0.95), quantile(ep$null, 0.95)),
  p = c(et$p, ep$p)
)
write_tab(energy, "c3_03_energy_test.csv")
print(as.data.frame(energy))

# Which law matches the calibration targets? ------------------------------------------
# Same comparison as cycle 2 (c2_01) for pi_x0, now for both laws, and for
# the new ir100.hiv.dx targets (cold-start runs only).
targets <- EpiModelHIV::get_calibration_targets()
tv <- targets[names(targets) %in% names(target_map_c3)]
tt <- bind_rows(lapply(names(tv), function(tn) {
  v <- target_map_c3[[tn]]
  pc <- pi_moments(Yc[[v]], rows)
  px <- if (v %in% names(Yx)) pi_moments(Yx[[v]], rows) else
    list(mu = NA_real_, s2 = NA_real_)
  tibble(
    target = tn, variable = v, target_value = tv[[tn]],
    pi_cold = pc$mu, sd_cold = sqrt(pc$s2),
    gap_cold_pct = 100 * (pc$mu / tv[[tn]] - 1),
    gap_cold_sd = (pc$mu - tv[[tn]]) / sqrt(pc$s2),
    pi_x0 = px$mu,
    gap_x0_pct = 100 * (px$mu / tv[[tn]] - 1),
    gap_x0_sd = (px$mu - tv[[tn]]) / sqrt(px$s2)
  )
}))
write_tab(tt, "c3_03_targets.csv")
print(as.data.frame(tt))

# Figures ----------------------------------------------------------------------
p <- laws |>
  filter(block %in% c("key", "project")) |>
  mutate(var = factor(var, rev(var))) |>
  ggplot(aes(d_mean, var, colour = p_mean < 0.05)) +
  geom_vline(xintercept = 0) +
  geom_errorbar(aes(xmin = d_mean_lo, xmax = d_mean_hi), width = 0,
    orientation = "y") +
  geom_point() +
  scale_colour_manual(values = c(`FALSE` = "grey50", `TRUE` = "firebrick"),
    labels = c("p >= 0.05", "p < 0.05")) +
  labs(x = "(mean cold start - mean x0 runs) / pooled SD_pi, years >= 300",
    y = NULL, colour = "permutation test",
    title = "Stationary means: cold-start runs vs the x0 runs of cycles 1-2",
    subtitle = "Key and project variables; bars: 95% chain bootstrap")
save_fig(p, "c3_03_law_means.png", 9, 11)

wk <- c("prev", "prev.B", "prev.H", "prev.W", "incid_rate", "dx_frac",
  "supp_frac", "prep_cov", "gono_prev", "chla_prev", "syph_prev", "num")
band <- bind_rows(lapply(wk, function(v) {
  bind_rows(
    tibble(run = "cold start", year = cold$years, m = rowMeans(Yc[[v]])),
    tibble(run = "x0 (cycles 1-2)", year = cold$years, m = rowMeans(Yx[[v]]))
  ) |> mutate(var = v)
}))
p <- band |>
  ggplot(aes(year, m, colour = run)) +
  geom_line(linewidth = 0.3) +
  facet_wrap(~var, scales = "free_y", ncol = 4) +
  labs(x = "Years after the start", y = "Cross-chain mean", colour = NULL,
    title = "Cross-chain means of the two experiments over 600 years") +
  theme(legend.position = "bottom")
save_fig(p, "c3_03_means_both.png", 13, 9)

save_session("c3_03")
