# =============================================================================
# c5_03_effects.R
# Question : For three forward scenarios (S1 testing, S2 PrEP, S3 STI
#            screening), how large is the effect, how much does it vary
#            between restart points (effect heterogeneity sigma_e, effect
#            ICC), is the variation what a proportional effect predicts, and
#            which pool design does that imply?
# Inputs   : data/run/restart_assessment/cycle5/c5_01_annual_short.rds,
#            data/run/restart_assessment/cycle4/c4_01_annual_pool.rds (pi)
# Outputs  : cycle5/results/tables/c5_03_*.csv, figures/c5_03_*.png
# Method   : c5_METHODS.md C5-M2, C5-M3; results/c5_03_effects.md
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
out <- lapply(sh$arms, short_outcomes)
scen <- c("s1_test", "s2_prep", "s3_sti")

# Outcomes and their stationary variance (for the level ICC icc_w) ------------------
# Counts over years 6-15 are "relative" outcomes (effect as a share of the
# baseline, PIA-like); year-15 values are "absolute" (effect in their units).
outc <- tribble(
  ~outcome,          ~var,           ~type,  ~scale,
  "cml_incid",       "hiv.incid",    "sum",  "relative",
  "cml_incid.B",     "hiv.incid.B",  "sum",  "relative",
  "cml_incid.H",     "hiv.incid.H",  "sum",  "relative",
  "cml_incid.W",     "hiv.incid.W",  "sum",  "relative",
  "cml_gono",        "gono.incid",   "sum",  "relative",
  "cml_chla",        "chla.incid",   "sum",  "relative",
  "cml_syph",        "syph.incid",   "sum",  "relative",
  "prev_y15",        "prev",         "value", "absolute",
  "incid_rate_y15",  "incid_rate",   "value", "absolute",
  "dx_frac_y15",     "dx_frac",      "value", "absolute",
  "prep_cov_y15",    "prep_cov",     "value", "absolute"
)
outc$v_pi <- vapply(seq_len(nrow(outc)), function(i) {
  y <- c4$Y[[outc$var[i]]]
  if (outc$type[i] == "sum") {
    window_ref(y, INT_L, LATE_START, 1, "sum")["var"]
  } else {
    pi_moments(y, LATE_START:N_YEARS)$s2
  }
}, numeric(1))

# Level ICC of the baseline arm (a replication of c4_04) ---------------------------
b <- out$baseline
lev <- bind_rows(lapply(seq_len(nrow(outc)), function(i) {
  li <- level_icc(b[[outc$outcome[i]]], b$point, outc$v_pi[i])
  tibble(outcome = outc$outcome[i], mean = mean(b[[outc$outcome[i]]]),
    sd_pi = sqrt(outc$v_pi[i]), cv_pi = sqrt(outc$v_pi[i]) / mean(b[[outc$outcome[i]]]),
    sb2 = li[["sb2"]], sw2 = li[["sw2"]], icc_a = li[["icc_a"]], icc_w = li[["icc_w"]])
}))
write_tab(lev, "c5_03_baseline_level_icc.csv")
print(as.data.frame(lev))

# Paired effects and heterogeneity -------------------------------------------------------
eff <- bind_rows(lapply(scen, function(s) {
  a <- out[[s]]
  bind_rows(lapply(seq_len(nrow(outc)), function(i) {
    o <- outc$outcome[i]
    ps <- point_summary(a[[o]], a$point, b[[o]], b$point)
    pe <- paired_effect(ps)
    # Point bootstrap of sigma_e (check on the F-based CI)
    bt <- point_boot_paired(a[[o]], a$point, b[[o]], b$point, function(p) {
      x <- paired_effect(p)
      c(x$s2_delta, x$pia)
    }, N_BOOT_C5)
    # Proportional-effect prediction (cycle 2, C2-M6): s2_delta = e^2 sb2,
    # with e the relative effect and sb2 the between-point variance of the
    # baseline level
    sb2 <- lev$sb2[lev$outcome == o]
    rel <- pe$delta / pe$mu0
    bind_cols(tibble(scenario = s, outcome = o, scale = outc$scale[i]), pe,
      tibble(s2_boot_lo = quantile(bt[, 1], 0.025), s2_boot_hi = quantile(bt[, 1], 0.975),
        s2_prop = rel^2 * sb2,
        prop_in_ci = pe$s2_lo <= rel^2 * sb2 & rel^2 * sb2 <= pe$s2_hi))
  }))
}))
write_tab(eff, "c5_03_effects.csv")
print(as.data.frame(eff |> filter(scale == "relative") |>
  transmute(scenario, outcome, pia_pct = 100 * pia, pia_se_pp = 100 * pia_se,
    sigma_e_pp = 100 * sigma_e, lo = 100 * sigma_e_lo, hi = 100 * sigma_e_hi,
    p_het, icc_delta, prop_in_ci)))
print(as.data.frame(eff |> filter(scale == "absolute") |>
  transmute(scenario, outcome, delta, se, sd_delta = sqrt(pmax(s2_delta, 0)),
    sd_hi = sqrt(pmax(s2_hi, 0)), p_het, icc_delta)))

# Does the effect depend on the point's initial state? (exploratory) ---------------
# One a-priori predictor per scenario, from the saved state of each point:
# S1 the undiagnosed share (testing acts on it), S2 HIV prevalence, S3
# gonorrhoea prevalence.
pred <- c(s1_test = "undx_frac", s2_prep = "prev", s3_sti = "gono_prev")
reg <- bind_rows(lapply(scen, function(s) {
  a <- out[[s]]
  o <- if (s == "s3_sti") "cml_gono" else "cml_incid"
  ps <- point_summary(a[[o]], a$point, b[[o]], b$point)
  dj <- (ps$ma - ps$m0) / mean(ps$m0)
  x <- sh$point_state[[pred[[s]]]][sort(unique(b$point))]
  f <- summary(lm(dj ~ scale(x)))
  tibble(scenario = s, outcome = o, predictor = pred[[s]],
    slope_pp_per_sd = 100 * f$coefficients[2, 1], se = 100 * f$coefficients[2, 2],
    p = f$coefficients[2, 4], r2 = f$r.squared)
}))
write_tab(reg, "c5_03_state_dependence.csv")
print(reg)

# Consequences for the design (SCENARIOS.md 4.2, with the measured values) --------
des <- bind_rows(lapply(seq_len(nrow(eff)), function(i) {
  e <- eff[i, ]
  l <- lev[lev$outcome == e$outcome, ]
  sw2 <- (e$swa + e$sw0) / 2
  r <- design_rmse(l$sb2, sw2, e$s2_delta, 32)
  r_hi <- design_rmse(l$sb2, sw2, e$s2_hi, 32)
  unit <- if (e$scale == "relative") 100 / e$mu0 else 1
  tibble(scenario = e$scenario, outcome = e$outcome, scale = e$scale,
    unit = if (e$scale == "relative") "pp of PIA" else "outcome units",
    !!!as.list(setNames(r * unit, names(r))),
    ratio_8_vs_32 = r[["paired_8"]] / r[["paired_32"]],
    ratio_8_vs_32_hi = r_hi[["paired_8"]] / r_hi[["paired_32"]],
    ratio_random_vs_8 = r[["random_32"]] / r[["paired_8"]])
}))
write_tab(des, "c5_03_design_rmse.csv")
print(as.data.frame(des |> filter(outcome %in% c("cml_incid", "cml_gono", "prev_y15"))))

# Heterogeneity of annual effects over the intervention years ---------------------
by_year <- bind_rows(lapply(scen, function(s) {
  bind_rows(lapply(c("prev", "incid_rate", "gono_prev"), function(v) {
    bind_rows(lapply((INT_B + 1):SHORT_YEARS, function(yr) {
      ya <- sh$arms[[s]]$Y[[v]][yr, ]
      y0 <- sh$arms$baseline$Y[[v]][yr, ]
      pe <- paired_effect(point_summary(ya, sh$arms[[s]]$point, y0,
        sh$arms$baseline$point))
      tibble(scenario = s, var = v, year = yr, delta = pe$delta,
        delta_lo = pe$delta_lo, delta_hi = pe$delta_hi,
        sd_delta = sqrt(max(pe$s2_delta, 0)), sd_hi = sqrt(max(pe$s2_hi, 0)),
        icc_delta = pe$icc_delta, p_het = pe$p_het)
    }))
  }))
}))
write_tab(by_year, "c5_03_by_year.csv")

# Figures ---------------------------------------------------------------------------------
fe <- eff |> filter(scale == "relative") |>
  mutate(label = SC_LABELS[scenario])
p <- ggplot(fe, aes(100 * pia, outcome)) +
  geom_vline(xintercept = 0, colour = "grey60") +
  geom_errorbar(aes(xmin = 100 * (pia - qt(0.975, k - 1) * pia_se),
    xmax = 100 * (pia + qt(0.975, k - 1) * pia_se)), width = 0.3, orientation = "y") +
  geom_point() + facet_wrap(~label, scales = "free_x") +
  labs(x = "Share of events averted over years 6-15 (%), paired 95% CI", y = NULL,
    title = "Average effects of the three forward scenarios")
save_fig(p, "c5_03_effects.png", height = 5)

p <- ggplot(fe, aes(100 * sigma_e, outcome)) +
  geom_vline(xintercept = SIGMA_E_THRESH[1], linetype = 2, colour = "darkgreen") +
  geom_vline(xintercept = SIGMA_E_THRESH[2], linetype = 2, colour = "firebrick") +
  geom_errorbar(aes(xmin = 100 * sigma_e_lo, xmax = 100 * sigma_e_hi), width = 0.3,
    orientation = "y") +
  geom_point() + facet_wrap(~label) +
  labs(x = "Effect heterogeneity sigma_e (pp), 95% CI", y = NULL,
    title = "How much the effect varies between restart points",
    subtitle = "Dashed: 0.6 pp (current 8-point design within 10% of 32) and 1.3 pp (random 32 better than paired 8)")
save_fig(p, "c5_03_heterogeneity.png", height = 5)

dj_tab <- bind_rows(lapply(scen, function(s) {
  o <- if (s == "s3_sti") "cml_gono" else "cml_incid"
  ps <- point_summary(out[[s]][[o]], out[[s]]$point, b[[o]], b$point)
  se_j <- sqrt(ps$swa / ps$na + ps$sw0 / ps$n0) / mean(ps$m0)
  tibble(label = SC_LABELS[s], outcome = o, point = seq_along(ps$ma),
    pia_j = -(ps$ma - ps$m0) / mean(ps$m0), se_j = se_j)
}))
p <- ggplot(dj_tab, aes(reorder(factor(point), pia_j), 100 * pia_j)) +
  geom_errorbar(aes(ymin = 100 * (pia_j - 2 * se_j), ymax = 100 * (pia_j + 2 * se_j)),
    width = 0, colour = "grey50") +
  geom_point() + facet_wrap(~ paste(label, "-", outcome), scales = "free") +
  labs(x = "Restart point (ordered)", y = "Point-level effect (% averted), +- 2 SE of chance",
    title = "Effect by restart point",
    subtitle = "If the spread of the points exceeds their error bars, the effect depends on the point") +
  theme(axis.text.x = element_blank())
save_fig(p, "c5_03_point_effects.png", height = 5)

saveRDS(list(eff = eff, lev = lev, des = des, by_year = by_year),
  fs::path(INTER5_DIR, "c5_03_effects.rds"))
save_session("c5_03")
