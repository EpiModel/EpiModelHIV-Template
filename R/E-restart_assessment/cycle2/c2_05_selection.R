# =============================================================================
# c2_05_selection.R
# Question : Should restart points be selected beyond "processes ongoing"?
#            Cycle 1 compared extreme selections (32 closest of 254). Here:
#   (a) the project's own filter (every STI ir100 >= 50% of its target,
#       3-choose_restart.R);
#   (b) selection intensity: keep the fraction q of candidates closest to the
#       actual calibration targets, then draw 32 of them;
#   (c) proper conditioning on the targets as noisy data: weight candidates
#       by a Gaussian likelihood with data-error SD = f * SD_pi and resample;
#   (d) regression to the mean of selected states during the research window.
#   Futures are the project outcomes: cumulative incidence over years 6-15
#   and diagnosed prevalence at year 15 after the candidate state.
# Inputs   : data/run/restart_assessment/01_annual.rds (cycle 1)
# Outputs  : cycle2/results/tables/c2_05_*.csv, figures/c2_05_*.png
# Method   : c2_METHODS.md C2-M7; results/c2_05_selection.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle2/c2_config.R")
source("R/E-restart_assessment/cycle2/c2_utils.R")
set.seed(SEED)

annual <- readRDS(ANNUAL_PATH)
Y <- add_project_vars(annual$Y)
n_c <- ncol(Y[[1]])
pi_rows <- LATE_START:N_YEARS

targets <- EpiModelHIV::get_calibration_targets()
# cc.prep (total) is left out: its target uses another definition than the
# ratio computed here (c2_01_targets_vs_pi.csv)
tnames <- setdiff(intersect(names(targets), names(target_map)), "cc.prep")
tvars <- target_map[tnames]
t_val <- targets[tnames]
sd_pi <- vapply(tvars, function(v) sqrt(pi_moments(Y[[v]], pi_rows)$s2),
  numeric(1))

# Futures: the project outcomes after the candidate state at year t0
fut_def <- list(
  cml_incid = c("cml_incid", "cml"), cml_incid.B = c("cml_incid.B", "cml"),
  cml_incid.H = c("cml_incid.H", "cml"), cml_incid.W = c("cml_incid.W", "cml"),
  i.prev.dx.B_15 = c("i.prev.dx.B", "value"),
  i.prev.dx.W_15 = c("i.prev.dx.W", "value"),
  prev_15 = c("prev", "value")
)
t0_grid <- seq(EQ_START + max(FEATURE_LAGS), N_YEARS - INT_END)
all_rows <- restart_rows(t0_grid, n_c)
fut_value <- function(rows, def) {
  if (def[2] == "cml") INT_L * restart_window(Y[[def[1]]], rows, INT_L, INT_B)$M
  else restart_value(Y[[def[1]]], rows, INT_END)
}
fut_ref <- vapply(fut_def, function(d) {
  f <- fut_value(all_rows, d)
  c(mu = mean(f), sd = sd(f))
}, numeric(2))

# (a) The project's own filter on stationary states --------------------------------
sti_ok <- function(rows) {
  ok <- rep(TRUE, nrow(rows))
  for (s in c("gono", "chla", "syph")) {
    ok <- ok & restart_value(Y[[paste0("ir100.", s)]], rows, 0) >=
      0.5 * targets[[paste0("ir100.", s)]]
  }
  ok
}
filt <- tibble(
  n_states = nrow(all_rows),
  pass_sti_filter = mean(sti_ok(all_rows)),
  min_ir100_syph_ratio = min(restart_value(Y[["ir100.syph"]], all_rows, 0)) /
    targets[["ir100.syph"]]
)
write_tab(filt, "c2_05_project_filter.csv")
print(filt)

# (b, c) Selection intensity and likelihood weighting --------------------------
# One replicate: one candidate per chain at a random stationary year (254 iid
# draws from pi); distance to targets in SD_pi units on the target statistics
# at t0.
strategies <- c(paste0("keep_q_", SEL_Q), paste0("weight_f_", SEL_F),
  "sti_filter")
one_rep <- function(r) {
  rows <- data.frame(t0 = sample(t0_grid, n_c, replace = TRUE),
    chain = seq_len(n_c))
  Zt <- vapply(tnames, function(tn) {
    (restart_value(Y[[tvars[[tn]]]], rows, 0) - t_val[[tn]]) / sd_pi[[tn]]
  }, numeric(n_c))
  d2 <- rowSums(Zt^2)
  fut <- vapply(fut_def, function(d) fut_value(rows, d), numeric(n_c))
  ok <- sti_ok(rows)
  pick <- list()
  for (q in SEL_Q) {
    keep <- order(d2)[seq_len(max(SEL_K, round(q * n_c)))]
    pick[[paste0("keep_q_", q)]] <- keep[sample.int(length(keep), SEL_K)]
  }
  ess <- c()
  for (f in SEL_F) {
    lw <- -0.5 * d2 / f^2
    w <- exp(lw - max(lw))
    ess[paste0("weight_f_", f)] <- sum(w)^2 / sum(w^2)
    pick[[paste0("weight_f_", f)]] <- sample.int(n_c, SEL_K, replace = TRUE,
      prob = w)
  }
  okid <- which(ok)
  pick[["sti_filter"]] <- okid[sample.int(length(okid), SEL_K)]
  bind_rows(lapply(names(pick), function(s) {
    idx <- pick[[s]]
    bind_rows(lapply(names(fut_def), function(o) {
      x <- fut[idx, o]
      tibble(rep = r, strategy = s, outcome = o,
        bias_sd = (mean(x) - fut_ref["mu", o]) / fut_ref["sd", o],
        bias_pct = 100 * (mean(x) / fut_ref["mu", o] - 1),
        var_ratio = var(x) / fut_ref["sd", o]^2,
        dist_t0 = mean(sqrt(d2[idx])),
        ess = if (s %in% names(ess)) ess[[s]] else NA_real_)
    }))
  }))
}
sel <- bind_rows(parallel::mclapply(seq_len(SEL_REPS), one_rep,
  mc.cores = N_CORES))
saveRDS(sel, fs::path(INTER2_DIR, "c2_05_selection_reps.rds"))
sel_sum <- sel |>
  summarise(
    mean_bias_sd = mean(bias_sd), mean_bias_pct = mean(bias_pct),
    rmse_sd = sqrt(mean(bias_sd^2)), mean_var_ratio = mean(var_ratio),
    mean_dist_to_targets = mean(dist_t0), mean_ess = mean(ess),
    .by = c(strategy, outcome)
  ) |>
  mutate(strategy = factor(strategy, strategies)) |>
  arrange(outcome, strategy)
write_tab(sel_sum, "c2_05_selection_summary.csv")
print(as.data.frame(filter(sel_sum, outcome %in% c("cml_incid",
  "i.prev.dx.B_15"))))

# (d) Regression to the mean of selected states --------------------------------
# For states picked by closeness to the targets (q = 0.125), follow the mean
# distance to the targets and the mean of i.prev.dx.B from t0 to t0 + 40,
# compared with random states. Values in SD_pi units of the target statistic.
rows <- data.frame(t0 = sample(t0_grid[t0_grid <= N_YEARS - 40], 5000,
  replace = TRUE), chain = sample.int(n_c, 5000, replace = TRUE))
Zt0 <- vapply(tnames, function(tn) {
  (restart_value(Y[[tvars[[tn]]]], rows, 0) - t_val[[tn]]) / sd_pi[[tn]]
}, numeric(nrow(rows)))
d0 <- sqrt(rowSums(Zt0^2))
close <- d0 <= quantile(d0, 0.125)
rtm <- bind_rows(lapply(0:40, function(h) {
  Zh <- vapply(tnames, function(tn) {
    (restart_value(Y[[tvars[[tn]]]], rows, h) - t_val[[tn]]) / sd_pi[[tn]]
  }, numeric(nrow(rows)))
  dh <- sqrt(rowSums(Zh^2))
  tibble(h = h,
    dist_selected = mean(dh[close]), dist_random = mean(dh),
    iprevB_z_selected = mean(Zh[close, "i.prev.dx.B"]),
    iprevB_z_random = mean(Zh[, "i.prev.dx.B"]),
    iprevB_sd_selected = sd(Zh[close, "i.prev.dx.B"]),
    iprevB_sd_random = sd(Zh[, "i.prev.dx.B"]))
}))
write_tab(rtm, "c2_05_regression_to_mean.csv")

# Figures ----------------------------------------------------------------------
p <- sel_sum |>
  filter(outcome %in% c("cml_incid", "cml_incid.B", "i.prev.dx.B_15",
    "prev_15")) |>
  ggplot(aes(strategy, mean_var_ratio, fill = outcome)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_col(position = "dodge") +
  labs(x = NULL, y = "Var(futures of the pool) / stationary value",
    fill = NULL,
    title = "Selection of 32 restart points and the variance of the outcomes",
    subtitle = paste0("keep_q: the fraction q closest to the calibration ",
      "targets; weight_f: likelihood weights with data SD = f x SD_pi")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_fig(p, "c2_05_selection.png", 11, 6)

p <- rtm |>
  tidyr::pivot_longer(c(dist_selected, dist_random)) |>
  ggplot(aes(h, value, colour = name)) +
  geom_line() +
  labs(x = "Years after the restart state", y = "Mean distance to targets (SD_pi units, 16 targets)",
    colour = NULL,
    title = "States selected for being close to the targets regress to the mean")
save_fig(p, "c2_05_regression_to_mean.png", 8, 5)

save_session("c2_05")
