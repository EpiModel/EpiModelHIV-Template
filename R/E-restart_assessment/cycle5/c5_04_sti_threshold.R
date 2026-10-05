# =============================================================================
# c5_04_sti_threshold.R
# Question : Does a scenario that lowers STI transmission (S3, and S2
#            through PrEP screening) push runs toward extinction, does its
#            effect depend on how much STI a restart state carries, and does
#            the "processes ongoing" filter matter for such effects?
# Inputs   : data/run/restart_assessment/cycle5/c5_01_annual_short.rds,
#            data/run/restart_assessment/cycle4/c4_01_annual_pool.rds (pi)
# Outputs  : cycle5/results/tables/c5_04_*.csv, figures/c5_04_*.png
# Method   : c5_METHODS.md C5-M4; results/c5_04_sti_threshold.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle5/c5_config.R")
source("R/E-restart_assessment/cycle5/c5_utils.R")
set.seed(SEED)

sh <- readRDS(SHORT_ANNUAL_PATH)
c4 <- readRDS(POOL_ANNUAL_PATH)
stis <- c("gono", "chla", "syph")

# Extinctions and how close runs come to them -----------------------------------------
# A year with a mean infected count of 0 means extinction (absorbing).
ext <- bind_rows(lapply(names(sh$arms), function(s) {
  Y <- sh$arms[[s]]$Y
  bind_rows(lapply(stis, function(x) {
    inf <- Y[[paste0(x, ".inf")]]
    prev <- Y[[paste0(x, "_prev")]]
    tibble(arm = s, sti = x, runs = ncol(inf),
      extinct = sum(colSums(inf == 0) > 0),
      min_prev_year15 = min(prev[SHORT_YEARS, ]),
      median_prev_year15 = median(prev[SHORT_YEARS, ]),
      q01_pi = quantile(c4$Y[[paste0(x, "_prev")]][LATE_START:N_YEARS, ], 0.01),
      runs_below_q01_pi_year15 = sum(prev[SHORT_YEARS, ] <
        quantile(c4$Y[[paste0(x, "_prev")]][LATE_START:N_YEARS, ], 0.01)))
  }))
}))
write_tab(ext, "c5_04_extinction.csv")
print(as.data.frame(ext))

# The filter: points whose saved STI prevalence is below the 1% quantile of pi
# (cycle 1 rule, GUIDE 2.13) -----------------------------------------------------------
ps_state <- sh$point_state
flag <- bind_rows(lapply(stis, function(x) {
  q <- quantile(c4$Y[[paste0(x, "_prev")]][LATE_START:N_YEARS, ], c(0.01, 0.05, 0.10))
  v <- ps_state[[paste0(x, "_prev")]]
  tibble(sti = x, q01 = q[1], q05 = q[2], q10 = q[3], min_point = min(v),
    points_below_q01 = sum(v < q[1]), points_below_q05 = sum(v < q[2]),
    points_below_q10 = sum(v < q[3]))
}))
write_tab(flag, "c5_04_filter_points.csv")
print(as.data.frame(flag))

# Effect against the point's initial STI prevalence, S3 (and S2) ----------------------
# Point-level shares averted of STI incidence over years 6-15, with the
# restart state's prevalence of the same STI; and the effect when the points
# in the lowest decile of that prevalence are left out (a stricter filter
# than the project's, to see whether low-STI points behave differently).
out <- lapply(sh$arms, short_outcomes)
dep <- bind_rows(lapply(c("s2_prep", "s3_sti"), function(s) {
  bind_rows(lapply(stis, function(x) {
    o <- paste0("cml_", x)
    ps <- point_summary(out[[s]][[o]], out[[s]]$point, out$baseline[[o]], out$baseline$point)
    pia_j <- -(ps$ma - ps$m0) / ps$m0
    x0 <- ps_state[[paste0(x, "_prev")]]
    f <- summary(lm(pia_j ~ scale(x0)))
    low <- x0 <= quantile(x0, 0.1)
    keep <- setdiff(seq_len(N_POINTS_C5), which(low))
    pe_all <- paired_effect(ps)
    ps_k <- point_summary(out[[s]][[o]][out[[s]]$point %in% keep],
      out[[s]]$point[out[[s]]$point %in% keep],
      out$baseline[[o]][out$baseline$point %in% keep],
      out$baseline$point[out$baseline$point %in% keep])
    pe_k <- paired_effect(ps_k)
    tibble(scenario = s, sti = x,
      slope_pp_per_sd = 100 * f$coefficients[2, 1], slope_se = 100 * f$coefficients[2, 2],
      p = f$coefficients[2, 4], r2 = f$r.squared,
      pia_all = 100 * pe_all$pia, pia_without_low10 = 100 * pe_k$pia,
      diff_pp = 100 * (pe_k$pia - pe_all$pia), se_all_pp = 100 * pe_all$pia_se)
  }))
}))
write_tab(dep, "c5_04_state_dependence.csv")
print(as.data.frame(dep))

# Figures --------------------------------------------------------------------------------
fig <- bind_rows(lapply(c("s2_prep", "s3_sti"), function(s) {
  bind_rows(lapply(stis, function(x) {
    o <- paste0("cml_", x)
    ps <- point_summary(out[[s]][[o]], out[[s]]$point, out$baseline[[o]], out$baseline$point)
    tibble(label = SC_LABELS[s], sti = x, prev0 = ps_state[[paste0(x, "_prev")]],
      pia_j = -(ps$ma - ps$m0) / ps$m0)
  }))
}))
p <- ggplot(fig, aes(100 * prev0, 100 * pia_j)) + geom_point() +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, colour = "firebrick") +
  facet_grid(label ~ sti, scales = "free") +
  labs(x = "STI prevalence of the restart state (%)",
    y = "Share of STI infections averted, years 6-15 (%)",
    title = "Does the STI effect depend on how much STI the restart state carries?",
    subtitle = "One point per restart state (mean of 4 runs per arm)")
save_fig(p, "c5_04_state_dependence.png")

traj <- bind_rows(lapply(c("baseline", "s3_sti"), function(s) {
  Y <- sh$arms[[s]]$Y
  bind_rows(lapply(stis, function(x) {
    m <- Y[[paste0(x, "_prev")]]
    tibble(arm = s, sti = x, year = rep(seq_len(SHORT_YEARS), ncol(m)),
      run = rep(seq_len(ncol(m)), each = SHORT_YEARS), prev = as.vector(m))
  }))
}))
p <- ggplot(traj, aes(year, 100 * prev, group = interaction(arm, run), colour = arm)) +
  geom_line(alpha = 0.15) + facet_wrap(~sti, scales = "free_y") +
  labs(x = "Year after the restart", y = "STI prevalence (%)",
    title = "STI prevalence of every run, baseline and S3")
save_fig(p, "c5_04_sti_runs.png")

save_session("c5_04")
