# =============================================================================
# 03_stationarity.R
# Question : Does every tracked variable have a stationary distribution, i.e.
#            no drift of the cross-chain mean or variance late in the runs?
# Inputs   : data/run/restart_assessment/01_annual.rds
# Outputs  : results/tables/03_drift.csv, results/figures/03_*.png
# Method   : METHODS.md M2.2; results/03_stationarity.md
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
vars <- dict$name[dict$block %in% c("key", "state")]
n_c <- ncol(Y[[1]])

# Drift tests (M2.2) -------------------------------------------------------------
# Regress the cross-chain mean and variance on time over each period; CIs by
# resampling whole chains and refitting. A variable is flagged when the CI
# excludes 0 and the drift exceeds the tolerance.
drift <- bind_rows(lapply(DRIFT_PERIODS, function(per) {
  yrs <- per[1]:per[2]
  bind_rows(lapply(vars, function(v) {
    est <- drift_stats(Y[[v]], yrs)
    bm <- chain_boot(n_c, N_BOOT, function(i) drift_stats(Y[[v]][, i], yrs))
    ci <- boot_ci(bm)
    tibble(
      var = v,
      block = dict$block[match(v, dict$name)],
      period = paste(per, collapse = "-"),
      mean_drift = est[1], mean_lo = ci[1, 1], mean_hi = ci[1, 2],
      var_drift = est[2], var_lo = ci[2, 1], var_hi = ci[2, 2]
    )
  }))
})) |>
  mutate(
    mean_flag = (mean_lo > 0 | mean_hi < 0) & abs(mean_drift) > MEAN_DRIFT_TOL,
    var_flag = (var_lo > 0 | var_hi < 0) & abs(var_drift) > VAR_DRIFT_TOL,
    flag = mean_flag | var_flag
  )
write_tab(drift, "03_drift.csv")
print(filter(drift, flag))
cat("Flagged:", sum(drift$flag), "of", nrow(drift), "\n")

# Century summaries --------------------------------------------------------------
# Mean and variance by 50-year block relative to the pi reference, a direct
# look at whether anything keeps moving.
blocks <- bind_rows(lapply(vars, function(v) {
  pm <- pi_moments(Y[[v]], LATE_START:N_YEARS)
  cm <- cross_moments(Y[[v]])
  tibble(var = v, year = annual$years, o = (cm$m - pm$mu) / sqrt(pm$s2),
    r = cm$v / pm$s2)
})) |>
  mutate(block50 = 50 * ((year - 1) %/% 50) + 25) |>
  summarise(offset = mean(o), var_ratio = mean(r), .by = c(var, block50))
write_tab(blocks, "03_block50_moments.csv")

key <- dict$name[dict$block == "key"]
p <- blocks |>
  filter(var %in% key) |>
  tidyr::pivot_longer(c(offset, var_ratio)) |>
  mutate(name = recode(name,
    offset = "mean offset (SD_pi units)",
    var_ratio = "variance ratio v(t) / v_pi")) |>
  ggplot(aes(block50, value, colour = var)) +
  geom_hline(data = data.frame(name = c("mean offset (SD_pi units)",
    "variance ratio v(t) / v_pi"), y = c(0, 1)), aes(yintercept = y),
    linetype = 2) +
  geom_line() +
  geom_point(size = 0.8) +
  facet_wrap(~name, scales = "free_y", ncol = 1) +
  labs(x = "Years after restart (50-year block centre)", y = NULL,
    colour = NULL,
    title = "Key variables: cross-chain moments by 50-year block",
    subtitle = "pi reference: years 300-600, all chains") +
  theme(legend.position = "right")
save_fig(p, "03_block50_moments.png", 11, 8)

save_session("03")
