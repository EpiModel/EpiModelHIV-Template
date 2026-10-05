# =============================================================================
# 07_pool_design.R
# Question : Can a pool of restart points remove the post-restart burn-in,
#            how many points are needed, how should they be generated, and
#            should they be selected beyond "all processes ongoing"?
# Inputs   : data/run/restart_assessment/01_annual.rds,
#            results/tables/05_acf.csv, 05_tau_int.csv, 06_icc_bounds.csv
# Outputs  : results/tables/07_*.csv, results/figures/07_*.png
# Method   : METHODS.md M3; results/07_pool_design.md
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
Y <- annual$Y
n_c <- ncol(Y[[1]])

icc <- read.csv(fs::path(TAB_DIR, "06_icc_bounds.csv"))
acf_tab <- read.csv(fs::path(TAB_DIR, "05_acf.csv"))
tau_tab <- read.csv(fs::path(TAB_DIR, "05_tau_int.csv"))

# Two ICC scenarios per output (M3.1) ----------------------------------------------
# - "lower bound": out-of-sample R^2 from pseudo-restarts, averaged over pi
#   (step 06). True ICC is at least this.
# - "single x0": 1 - Var(. | x0) / Var_pi measured directly on the 254 runs
#   from x0 (step 04). One draw of x0 only, and x0 is atypical, so it is an
#   illustration of what a real restart state does, not an average.
# The design value used below is the larger of the two point estimates,
# clipped to [0, 1]: a conservative choice for pool sizes.
icc <- icc |>
  mutate(icc_design = pmin(1, pmax(0, icc_lb, icc_x0, na.rm = TRUE)))

# Variance and MCSE for a pool of k points (M3.1) ---------------------------------
# k points iid from pi, N research runs spread evenly over them (n = N / k).
# For an output with ICC c and stationary variance V:
#   expected across-run variance = V [1 - c (N - n) / (N - 1) / ...] ~
#     V (1 - c / k) for large n (deficit c / k)
#   Var(grand mean) = V [c / k + (1 - c) / N]
#   inflation vs one point per run (k = N) = 1 + c (N / k - 1)
#   points needed for inflation <= 1 + g: k >= N c / (g + c)
win_icc <- icc |> filter(functional == "window_mean")
design <- bind_rows(lapply(PLANNED_N, function(N) {
  bind_rows(lapply(POOL_K[POOL_K <= N], function(k) {
    win_icc |>
      transmute(var, B = h, icc_design, N = N, k = k,
        var_deficit = icc_design / k,
        mcse_inflation = sqrt(1 + icc_design * (N / k - 1)))
  }))
}))
write_tab(design, "07_pool_mcse.csv")

k_needed <- win_icc |>
  select(var, B = h, icc_lb, icc_x0, icc_design) |>
  tidyr::crossing(N = PLANNED_N) |>
  mutate(
    k_deficit_5pct = ceiling(icc_design / 0.05),
    k_deficit_10pct = ceiling(icc_design / 0.10),
    k_mcse_10pct = ceiling(N * icc_design / (1.1^2 - 1 + icc_design)),
    k_mcse_25pct = ceiling(N * icc_design / (1.25^2 - 1 + icc_design))
  )
write_tab(k_needed, "07_k_needed.csv")

# Time to full variance as a function of pool size (M3.1) ------------------------
# For annual values h years after restart: deficit(h, k) = ICC(h) / k.
# T(k, eps) = first h from which the deficit stays <= eps.
val_icc <- icc |> filter(functional == "value")
t_of_k <- val_icc |>
  select(var, h, icc_lb, icc_x0) |>
  tidyr::pivot_longer(c(icc_lb, icc_x0), names_to = "scenario",
    values_to = "icc") |>
  tidyr::crossing(k = POOL_K, eps = c(0.05, 0.1)) |>
  arrange(var, scenario, k, eps, h) |>
  summarise(
    T_h = {
      bad <- which(pmax(icc, 0) / k > eps)
      if (!length(bad)) 0 else if (max(bad) == length(h)) NA else
        h[max(bad) + 1]
    },
    .by = c(var, scenario, k, eps)
  )
write_tab(t_of_k, "07_time_to_full_by_k.csv")

# Generating the pool: independent chains vs one chain with spacing d (M3.2) ------
# Points taken from one chain d years apart are correlated. With the pooled
# ACF as a proxy for the correlation of what the points carry, the effective
# pool size of k points is k^2 / sum_ij rho(|i - j| d).
k_eff <- function(rho, k, d) {
  lags <- abs(outer(seq_len(k), seq_len(k), "-")) * d
  r <- ifelse(lags <= max(acf_tab$lag), rho[pmin(lags, max(acf_tab$lag)) + 1],
    0)
  k^2 / sum(pmax(r, 0))
}
slow <- head(tau_tab$var[tau_tab$block == "key"], 3)
spacing <- bind_rows(lapply(slow, function(v) {
  rho <- acf_tab$rho[acf_tab$var == v]
  tidyr::crossing(k = c(8, 16, 32, 64), d = c(5, 10, 20, 30, 50, 75)) |>
    rowwise() |>
    mutate(var = v, k_eff = k_eff(rho, k, d)) |>
    ungroup()
}))
write_tab(spacing, "07_single_chain_spacing.csv")

# Selection experiment (M3.3) --------------------------------------------------------
# Candidates: one state per chain at a random stationary year t0, i.e. 254
# iid draws from pi, exactly what 254 parallel chains run past T_full would
# give. Each candidate has one realised 20-year future (years t0+1 ... t0+20).
# Strategies pick SEL_K candidates:
#   random      : simple random sample
#   ongoing     : drop candidates with any STI prevalence below its pi 1%
#                 quantile (a "processes ongoing" filter), then random
#   typical     : the SEL_K closest to the pi mean of all key + state
#                 variables (whitened), i.e. "most representative" states
#   target_like : the SEL_K closest to the pi means of five headline outputs
#                 (prev, incid_rate, dx_frac, supp_frac, prep_cov), mimicking
#                 selection on calibration targets
#   stratified  : SEL_K equal-size strata on the first principal component
#                 of the state, one random candidate per stratum
# For each strategy and replicate we record, for each key output, the pool's
# bias (mean of the futures minus the pi mean, in SD_pi(M) units) and the
# ratio of the variance of the futures to Var_pi(M) (1 run per point).
t0_grid <- seq(EQ_START + max(FEATURE_LAGS), N_YEARS - WINDOW_L)
feat_vars <- c(key, state)
pi_rows <- LATE_START:N_YEARS
mu_pi <- vapply(feat_vars, function(v) pi_moments(Y[[v]], pi_rows)$mu,
  numeric(1))
sd_pi <- vapply(feat_vars, function(v) sqrt(pi_moments(Y[[v]], pi_rows)$s2),
  numeric(1))

# pi reference for the window functionals, from all stationary windows
all_rows <- restart_rows(seq(EQ_START, N_YEARS - WINDOW_L, 1), n_c)
win_ref <- bind_rows(lapply(key, function(v) {
  w <- restart_window(Y[[v]], all_rows, WINDOW_L)
  tibble(var = v, M_mu = mean(w$M), M_sd = sd(w$M), S2_mu = mean(w$S2))
}))

# PCA of the standardised state at stationarity, for "typical" and strata
S_pi <- sapply(feat_vars, function(v) {
  (as.vector(Y[[v]][pi_rows, ]) - mu_pi[v]) / sd_pi[v]
})
e <- eigen(cov(S_pi), symmetric = TRUE)
n_pc <- which(cumsum(e$values) / sum(e$values) >= PCA_VAR)[1]
W <- e$vectors[, 1:n_pc] %*% diag(1 / sqrt(e$values[1:n_pc]))
rm(S_pi)
headline <- c("prev", "incid_rate", "dx_frac", "supp_frac", "prep_cov")
sti_prev <- c("gono_prev", "chla_prev", "syph_prev")
q01 <- vapply(sti_prev, function(v) quantile(Y[[v]][pi_rows, ], 0.01),
  numeric(1))

select_pool <- function(strategy, Sz, Zw, raw_sti, k) {
  n <- nrow(Sz)
  switch(strategy,
    random = sample.int(n, k),
    ongoing = {
      ok <- which(apply(sweep(raw_sti, 2, q01, ">"), 1, all))
      ok[sample.int(length(ok), k)]
    },
    typical = order(rowSums(Zw^2))[1:k],
    target_like = order(rowSums(Sz[, headline]^2))[1:k],
    stratified = {
      o <- order(Zw[, 1])
      strata <- split(o, cut(seq_along(o), k, labels = FALSE))
      vapply(strata, function(s) s[sample.int(length(s), 1)], integer(1))
    }
  )
}
strategies <- c("random", "ongoing", "typical", "target_like", "stratified")

sel <- bind_rows(parallel::mclapply(seq_len(SEL_REPS), mc.cores = N_CORES,
  function(r) {
    rows <- data.frame(t0 = sample(t0_grid, n_c, replace = TRUE),
      chain = seq_len(n_c))
    raw <- restart_features(Y, feat_vars, rows)
    colnames(raw) <- feat_vars
    Sz <- sweep(sweep(raw, 2, mu_pi), 2, sd_pi, "/")
    Zw <- Sz %*% W
    fut <- lapply(setNames(key, key), function(v) {
      restart_window(Y[[v]], rows, WINDOW_L)
    })
    bind_rows(lapply(strategies, function(s) {
      idx <- select_pool(s, Sz, Zw, raw[, sti_prev], SEL_K)
      bind_rows(lapply(key, function(v) {
        ref <- win_ref[win_ref$var == v, ]
        M <- fut[[v]]$M[idx]
        tibble(rep = r, strategy = s, var = v,
          bias = (mean(M) - ref$M_mu) / ref$M_sd,
          var_ratio = var(M) / ref$M_sd^2,
          within_ratio = mean(fut[[v]]$S2[idx]) / ref$S2_mu)
      }))
    }))
  }))
saveRDS(sel, fs::path(INTER_DIR, "07_selection_reps.rds"))

sel_sum <- sel |>
  summarise(
    mean_bias = mean(bias),
    rmse_pool_mean = sqrt(mean(bias^2)),
    mean_var_ratio = mean(var_ratio),
    var_ratio_q05 = quantile(var_ratio, 0.05),
    var_ratio_q95 = quantile(var_ratio, 0.95),
    mean_within_ratio = mean(within_ratio),
    .by = c(strategy, var)
  ) |>
  mutate(rmse_random_theory = 1 / sqrt(SEL_K))
write_tab(sel_sum, "07_selection_summary.csv")
sel_overall <- sel_sum |>
  summarise(across(c(mean_bias, rmse_pool_mean, mean_var_ratio,
    mean_within_ratio), list(min = min, median = median, max = max)),
    .by = strategy)
write_tab(sel_overall, "07_selection_overall.csv")
print(as.data.frame(sel_overall))

# Figures ----------------------------------------------------------------------
p <- t_of_k |>
  filter(eps == 0.1, var %in% c("prev", "prev.B", "prev.W", "incid_rate",
    "dx_frac", "chla_prev", "gono_prev", "syph_prev", "num")) |>
  ggplot(aes(k, T_h, colour = scenario)) +
  geom_line() +
  geom_point() +
  scale_x_log10(breaks = POOL_K) +
  facet_wrap(~var) +
  labs(x = "Pool size k (points iid from pi)",
    y = "Years after restart until deficit <= 10%", colour = NULL,
    title = "Post-restart burn-in needed as a function of pool size",
    subtitle = "Deficit of annual values = ICC(h) / k")
save_fig(p, "07_time_to_full_by_k.png", 10, 8)

p <- sel_sum |>
  ggplot(aes(mean_var_ratio, rmse_pool_mean, colour = strategy)) +
  geom_vline(xintercept = 1, linetype = 2) +
  geom_hline(yintercept = 1 / sqrt(SEL_K), linetype = 3) +
  geom_point() +
  labs(x = "Mean Var(futures) / Var_pi (1 = full between-run variance)",
    y = "RMSE of the pool mean (SD_pi units)", colour = NULL,
    title = paste0("Selecting ", SEL_K, " restart points out of ", n_c,
      " stationary candidates"),
    subtitle = "One point per key output. Dotted: random-sampling RMSE.")
save_fig(p, "07_selection.png", 9, 6)

save_session("07")
