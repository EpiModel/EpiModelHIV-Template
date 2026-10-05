# =============================================================================
# 06_restart_memory.R
# Question : What share of the variance of an output h years after a restart
#            (or of a 20-year window started after a burn-in B) is fixed by
#            the restart state, i.e. ICC(h), averaged over states drawn
#            from pi?
# Inputs   : data/run/restart_assessment/01_annual.rds,
#            results/tables/04_icc_x0.csv, 04_window_burnin.csv,
#            05_rho_reference.csv
# Outputs  : results/tables/06_*.csv, results/figures/06_*.png
# Method   : METHODS.md M2.2, M2.3; results/06_restart_memory.md
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
feat_vars <- c(key, state)
Y <- annual$Y
n_c <- ncol(Y[[1]])
WIN_B <- c(0, 5, 10, 20, 30) # burn-ins for the window responses

# Pseudo-restart rows (M2.3) -------------------------------------------------------
# Every (chain, t0) with t0 in the stationary period, spaced by
# PSEUDO_RESTART_STEP years, leaving room for the longest response.
t0_max <- N_YEARS - max(max(H_SUBSET), max(WIN_B) + WINDOW_L)
t0s <- seq(EQ_START + max(FEATURE_LAGS), t0_max, PSEUDO_RESTART_STEP)
rows <- restart_rows(t0s, n_c)
cat("Pseudo-restarts:", nrow(rows), "(", length(t0s), "per chain )\n")

# Features: every key and state variable at t0 and t0 - lag. Nothing after t0.
X <- restart_features(Y, feat_vars, rows, FEATURE_LAGS)
cat("Features:", ncol(X), "\n")

# Responses ----------------------------------------------------------------------
resp <- list()
resp_meta <- list()
for (v in key) {
  for (h in H_SUBSET) {
    nm <- paste0(v, "|value|h", h)
    resp[[nm]] <- restart_value(Y[[v]], rows, h)
    resp_meta[[nm]] <- tibble(var = v, functional = "value", h = h)
  }
  for (B in WIN_B) {
    w <- restart_window(Y[[v]], rows, WINDOW_L, B)
    nm <- paste0(v, "|M|B", B)
    resp[[nm]] <- w$M
    resp_meta[[nm]] <- tibble(var = v, functional = "window_mean", h = B)
    if (B == 0) {
      resp[[paste0(v, "|S2|B0")]] <- w$S2
      resp_meta[[paste0(v, "|S2|B0")]] <- tibble(var = v,
        functional = "window_var", h = 0)
      resp[[paste0(v, "|slope|B0")]] <- w$slope
      resp_meta[[paste0(v, "|slope|B0")]] <- tibble(var = v,
        functional = "window_slope", h = 0)
    }
  }
}
R <- do.call(cbind, resp)
meta <- bind_rows(resp_meta) |> mutate(response = colnames(R))
cat("Responses:", ncol(R), "\n")

# Timing of one fit, then all fits -----------------------------------------------
t_one <- system.time(
  ridge_cv(X, R[, 1:2], rows$chain, CV_FOLDS, RIDGE_LAMBDAS)
)["elapsed"]
cat("One ridge_cv call (2 responses):", t_one, "s\n")

# Full state model: all features, lambda chosen per response
pred_full <- ridge_cv(X, R, rows$chain, CV_FOLDS, RIDGE_LAMBDAS)

# Own-value model: only the response variable's own value at t0 (R^2 ~
# rho(h)^2 for values)
pred_own <- R
for (v in key) {
  cols <- which(meta$var == v)
  Xo <- restart_features(Y, v, rows)
  pred_own[, cols] <- ridge_cv(Xo, R[, cols, drop = FALSE], rows$chain,
    CV_FOLDS, RIDGE_LAMBDAS)
}

# Out-of-sample R^2 with chain-bootstrap CIs ---------------------------------------
r2 <- bind_rows(parallel::mclapply(seq_len(ncol(R)), mc.cores = N_CORES,
  function(j) {
    y <- R[, j]
    ybar <- mean(y)
    f <- r2_boot(y, pred_full[, j], ybar, rows$chain, N_BOOT)
    o <- r2_boot(y, pred_own[, j], ybar, rows$chain, N_BOOT)
    tibble(r2_full = f[1], r2_full_lo = f[2], r2_full_hi = f[3],
      r2_own = o[1], r2_own_lo = o[2], r2_own_hi = o[3])
  }))
res <- bind_cols(meta, r2) |>
  mutate(
    # the bound is the best of the models, clipped at 0; taking the max of
    # two models adds negligible optimism with ~20k rows
    icc_lb = pmax(0, r2_full, r2_own),
    icc_lb_lo = pmax(0, ifelse(r2_full >= r2_own, r2_full_lo, r2_own_lo))
  )

# Add the reference curves and the direct single-x0 estimates ----------------------
rho_ref <- read.csv(fs::path(TAB_DIR, "05_rho_reference.csv"))
icc_x0 <- read.csv(fs::path(TAB_DIR, "04_icc_x0.csv"))
win_x0 <- read.csv(fs::path(TAB_DIR, "04_window_burnin.csv")) |>
  transmute(var, h = B, functional = "window_mean", icc_x0 = 1 - between,
    icc_x0_lo = 1 - between_hi, icc_x0_hi = 1 - between_lo)
res <- res |>
  left_join(rho_ref |> mutate(functional = "value"),
    by = c("var", "h", "functional")) |>
  left_join(
    bind_rows(icc_x0 |> mutate(functional = "value") |>
      rename(icc_x0 = icc, icc_x0_lo = icc_lo, icc_x0_hi = icc_hi), win_x0),
    by = c("var", "h", "functional"))
write_tab(select(res, -response), "06_icc_bounds.csv")

# Summary at the research-relevant points
sum_tab <- res |>
  filter((functional == "value" & h %in% c(1, 5, 10, 20)) |
    (functional == "window_mean")) |>
  transmute(var, functional, h,
    lower_bound = sprintf("%.3f [%.3f, %.3f]", icc_lb,
      ifelse(r2_full >= r2_own, r2_full_lo, r2_own_lo),
      ifelse(r2_full >= r2_own, r2_full_hi, r2_own_hi)),
    direct_x0 = sprintf("%.3f [%.3f, %.3f]", icc_x0, icc_x0_lo, icc_x0_hi))
write_tab(sum_tab, "06_icc_summary.csv")

# Figures ----------------------------------------------------------------------
p <- res |>
  filter(functional == "value") |>
  ggplot(aes(h)) +
  geom_ribbon(aes(ymin = pmax(icc_x0_lo, -0.2), ymax = pmin(icc_x0_hi, 1.2)),
    fill = "grey70", alpha = 0.5) +
  geom_line(aes(y = icc_x0, colour = "direct, single x0 (1 - v/v_pi)")) +
  geom_ribbon(aes(ymin = r2_full_lo, ymax = r2_full_hi), fill = "steelblue",
    alpha = 0.3) +
  geom_line(aes(y = r2_full, colour = "lower bound: ridge on state")) +
  geom_line(aes(y = r2_own, colour = "lower bound: own value")) +
  geom_line(aes(y = rho_h2, colour = "rho(h)^2"), linetype = 2) +
  geom_line(aes(y = rho_2h, colour = "rho(2h) (heuristic)"), linetype = 3) +
  geom_hline(yintercept = 0) +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(ylim = c(-0.1, 1)) +
  scale_colour_manual(values = c("black", "steelblue", "darkorange",
    "purple", "grey40")) +
  labs(x = "Horizon h (years after restart)", y = "ICC(h)", colour = NULL,
    title = "Share of variance fixed by the restart state, annual values") +
  theme(legend.position = "bottom")
save_fig(p, "06_icc_values.png", 14, 13)

p <- res |>
  filter(functional == "window_mean") |>
  ggplot(aes(h)) +
  geom_errorbar(aes(ymin = icc_x0_lo, ymax = icc_x0_hi, colour = "direct x0"),
    width = 0.8) +
  geom_point(aes(y = icc_x0, colour = "direct x0")) +
  geom_errorbar(aes(ymin = r2_full_lo, ymax = r2_full_hi,
    colour = "lower bound (ridge)"), width = 0.8) +
  geom_point(aes(y = r2_full, colour = "lower bound (ridge)")) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = ICC_THRESHOLD, linetype = 3) +
  facet_wrap(~var, ncol = 5) +
  coord_cartesian(ylim = c(-0.3, 1)) +
  labs(x = "Burn-in B before the 20-year window (years)",
    y = "ICC of the 20-year window mean", colour = NULL,
    title = "Share of the window-mean variance fixed by the restart state") +
  theme(legend.position = "bottom")
save_fig(p, "06_icc_window_mean.png", 14, 13)

save_session("06")
