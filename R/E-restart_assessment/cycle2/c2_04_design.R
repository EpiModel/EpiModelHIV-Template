# =============================================================================
# c2_04_design.R
# Question : What do the restart-memory numbers mean for the designs the
#            project actually uses?
#   (a) intervention runs: 32 runs per scenario, 15 years after restart,
#       outcomes = cumulative incidence over years 6-15 and incidence in year
#       15, NIA / PIA against the baseline median (outcomes.R);
#   (b) calibration runs: 70 years after restart, targets over the last year;
#   for a single restart point, a pool used through EpiModel's default
#   recycling (only the first `n_cores` = 8 points are used), a randomised
#   pool, and levels vs intervention effects.
# Inputs   : cycle2 tables c2_02_icc_compare.csv, c2_02_direct_cml_incidence.csv,
#            data/run/restart_assessment/cycle2/c2_02_direct_values.rds
# Outputs  : cycle2/results/tables/c2_04_*.csv, figures/c2_04_*.png
# Method   : c2_METHODS.md C2-M6; results/c2_04_design.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle2/c2_config.R")
source("R/E-restart_assessment/cycle2/c2_utils.R")

cmp <- read.csv(fs::path(TAB_DIR, "c2_02_icc_compare.csv"))
cml <- read.csv(fs::path(TAB_DIR, "c2_02_direct_cml_incidence.csv"))
dv <- readRDS(fs::path(INTER2_DIR, "c2_02_direct_values.rds"))

# The ICC to use for a restart point drawn from pi under the SAME parameters
# is not observed. Two values bracket it for design purposes (C2-M4):
#   lb     : lower bound (pseudo-restarts), rigorous;
#   direct : 1 - Var(. | x0) / Var_pi on the runs from x0, a point estimate
#            for a restart point made with OTHER parameters.
design_icc <- function(var, functional, h) {
  r <- cmp[cmp$var == var & cmp$functional == functional & cmp$h == h, ]
  c(lb = max(0, r$lb), direct = min(1, max(0, r$icc_x0)))
}

# (a) Intervention outcomes -----------------------------------------------------
outs <- bind_rows(
  tibble(outcome = "cml incidence, years 6-15",
    var = c("cml_incid", "cml_incid.B", "cml_incid.H", "cml_incid.W"),
    functional = "cml10", h = INT_B),
  tibble(outcome = "incidence rate, year 15",
    var = c("incid_rate", "incid_rate.B", "incid_rate.H", "incid_rate.W"),
    functional = "value", h = INT_END)
)
N <- N_REP_INT
n_pt <- N / N_CORES_INT # runs per point with default recycling
single <- bind_rows(lapply(seq_len(nrow(outs)), function(i) {
  o <- outs[i, ]
  ic <- design_icc(o$var, o$functional, o$h)
  if (o$functional == "cml10") {
    d <- cml[cml$var == o$var & cml$B == o$h, ]
    sd_ratio <- sqrt(d$between)
    off_sd <- d$o_sd
    off_pct <- d$o_pct
    cv <- d$pi_cv_pct
  } else {
    d <- dv[dv$var == o$var & dv$h == o$h, ]
    sd_ratio <- sqrt(d$r)
    off_sd <- d$o_sd
    off_pct <- d$o_pct
    cv <- NA
  }
  tibble(o,
    icc_lb = ic["lb"], icc_direct = ic["direct"],
    # current practice: every run from x0
    x0_sd_ratio = sd_ratio, x0_offset_sd = off_sd, x0_offset_pct = off_pct,
    pi_cv_pct = cv,
    # same-parameter single point: SD ratio is sqrt(1 - ICC)
    single_sd_ratio_lb = sqrt(1 - ic["lb"]),
    single_sd_ratio_direct = sqrt(1 - ic["direct"]),
    # pool from pi used through recycling: 8 points x 4 runs
    recycle_var_deficit_lb = ic["lb"] * (n_pt - 1) / (N - 1),
    recycle_var_deficit_direct = ic["direct"] * (n_pt - 1) / (N - 1),
    recycle_mcse_infl_lb = sqrt(1 + ic["lb"] * (n_pt - 1)),
    recycle_mcse_infl_direct = sqrt(1 + ic["direct"] * (n_pt - 1)),
    # randomised restart, k = 8 points, with replacement (multinomial)
    random8_mcse_infl_direct = sqrt(1 + ic["direct"] * (N - 1) / N_CORES_INT),
    # points needed for an MCSE inflation <= 10% with N = 32 and 256
    k_mcse10_N32 = ceiling(32 * ic["direct"] / (0.21 + ic["direct"])),
    k_mcse10_N256 = ceiling(256 * ic["direct"] / (0.21 + ic["direct"]))
  )
}))
write_tab(single, "c2_04_intervention_design.csv")
print(as.data.frame(single))

# (a') Intervention effects: PIA and NIA -------------------------------------
# outcomes.R: PIA_i = (m_ref - Y_i) / m_ref, NIA_i = m_ref - Y_i, with m_ref
# the median over baseline runs. Model: Y = g(X) (1 + e_within), the
# intervention multiplies the conditional mean by (1 - e(X)).
#   If e(X) = e for every state (proportional effect), the pool mean of g
#   cancels in PIA to first order: the median PIA estimates e without bias
#   even from ONE restart point, and the pool only widens the per-run spread
#   (SD of PIA_i = (1 - e) CV of Y, between + within).
#   Effect heterogeneity across states, SD sigma_e, is what a single point
#   cannot average out: bias ~ N(0, sigma_e^2). It matters when sigma_e is
#   comparable to the Monte Carlo SE of the PIA estimate from within-point
#   noise. With medians in both arms (the baseline median m_ref and the
#   median of PIA_i over N intervention runs), each median has variance
#   ~ (pi / 2) / N times the per-run variance for near-normal outcomes, so
#   MCSE ~ (1 - e) CV_within sqrt(pi / N).
# The table gives, for each outcome and planned N, the MCSE and the effect
# heterogeneity sigma_e at which a single point doubles the RMSE
# (sigma_e = sqrt(3) MCSE).
cv_tab <- cml |>
  filter(B == INT_B) |>
  select(var, pi_cv_pct, between) |>
  mutate(icc_direct = pmin(1, pmax(0, 1 - between)))
eff <- tidyr::crossing(cv_tab, e = c(0.05, 0.1, 0.2, 0.3),
  N = c(32, 128, 256)) |>
  mutate(
    cv_within_pct = pi_cv_pct * sqrt(1 - icc_direct),
    pia_run_sd_pct_pool = 100 * (1 - e) * pi_cv_pct / 100,
    pia_run_sd_pct_single = 100 * (1 - e) * cv_within_pct / 100,
    pia_mcse_pct = 100 * (1 - e) * (cv_within_pct / 100) * sqrt(pi / N),
    sigma_e_double_rmse_pct = sqrt(3) * pia_mcse_pct
  )
write_tab(eff, "c2_04_effects_pia.csv")

# (b) Calibration from a restart -------------------------------------------------
# Share of run-to-run variance of each target fixed by the restart, and the
# imprint of x0 (other parameters) on the mean, by run length h.
cal_vars <- unique(unname(target_map))
cal <- bind_rows(lapply(cal_vars, function(v) {
  bind_rows(lapply(c(10, 20, 30, 50, 70), function(h) {
    ic <- design_icc(v, "value", h)
    d <- dv[dv$var == v & dv$h == h, ]
    tibble(variable = v, run_length = h, icc_lb = ic["lb"],
      icc_direct = ic["direct"], x0_offset_sd = d$o_sd,
      x0_offset_lo = d$o_lo, x0_offset_hi = d$o_hi,
      x0_offset_pct = d$o_pct)
  }))
}))
cal <- cal |> left_join(
  tibble(variable = unname(target_map), target = names(target_map)),
  by = "variable", relationship = "many-to-many")
write_tab(cal, "c2_04_calibration_run_length.csv")

# Figures ----------------------------------------------------------------------
p <- cal |>
  filter(target != "cc.prep") |>
  ggplot(aes(run_length)) +
  geom_hline(yintercept = 0) +
  geom_line(aes(y = icc_direct, colour = "variance fixed by x0 (direct)")) +
  geom_line(aes(y = icc_lb, colour = "variance fixed, lower bound (same param.)")) +
  geom_line(aes(y = abs(x0_offset_sd) / 2,
    colour = "|x0 mean imprint| / 2 (SD units)"), linetype = 2) +
  facet_wrap(~target, ncol = 4) +
  scale_colour_manual(values = c("darkorange", "black", "steelblue")) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(x = "Calibration run length after the restart (years)", y = NULL,
    colour = NULL,
    title = "Calibration targets: memory of the restart point by run length") +
  theme(legend.position = "bottom")
save_fig(p, "c2_04_calibration_run_length.png", 12, 10)

save_session("c2_04")
