# =============================================================================
# c3_05_workflow.R
# Question : What does the cold-start transient mean for the project's
#            workflow?
#   (a) Ballpark calibration: runs from a cold start whose targets are read
#       over the last year of a T-year run (swfcalib_model.R, T = 70). How
#       biased is each target, and how long must the runs be?
#   (b) Restart points taken at year B of cold-start runs (the pool of
#       3-choose_restart.R is taken at B = 70). How biased and how spread
#       are the research outcomes of runs started from them (cumulative
#       incidence over years 6-15, year-15 values, 20-year windows), and
#       which B is needed? The same for restarts from x0 (cycles 1-2).
# Inputs   : data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            data/run/restart_assessment/cycle3/c3_04_curves.rds,
#            data/run/restart_assessment/01_annual.rds (cycle 1, read-only)
# Outputs  : cycle3/results/tables/c3_05_*.csv, figures/c3_05_*.png
# Method   : c3_METHODS.md C3-M3, C3-M4; results/c3_05_workflow.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

cold <- readRDS(COLD_ANNUAL_PATH)
Yc <- cold$Y
Yx <- add_project_vars(readRDS(X0_ANNUAL_PATH)$Y)
curves <- readRDS(fs::path(INTER3_DIR, "c3_04_curves.rds"))
pi_rows <- LATE_START:N_YEARS
fit_t <- FIT_START:LATE_START
n_c <- ncol(Yc[[1]])

# (a) Calibration targets read after T years from a cold start ------------------
# The target of a T-year run is the value in year T (annual ratio of
# aggregates, C2-M1). Its bias against pi_cold (SD and %) comes from the
# c3_04 curves; the gap to the target value adds the bias to the gap of
# pi_cold itself (c3_03).
targets <- EpiModelHIV::get_calibration_targets()
tv <- targets[names(targets) %in% names(target_map_c3)]
tmap <- tibble(target = names(tv), var = unname(target_map_c3[names(tv)]),
  target_value = unname(tv))
pi_c <- bind_rows(lapply(unique(tmap$var), function(v) {
  pm <- pi_moments(Yc[[v]], pi_rows)
  tibble(var = v, pi_mean = pm$mu, pi_sd = sqrt(pm$s2))
}))
calib <- curves |>
  filter(year %in% CALIB_T) |>
  inner_join(tmap, by = "var", relationship = "many-to-many") |>
  left_join(pi_c, by = "var") |>
  transmute(target, var, run_years = year, target_value, pi_mean, pi_sd,
    bias_sd = o, bias_sd_lo = o_lo, bias_sd_hi = o_hi,
    bias_pct = pct, bias_pct_lo = pct_lo, bias_pct_hi = pct_hi,
    var_ratio = r,
    gap_to_target_pct = 100 * (pi_mean * (1 + pct / 100) / target_value - 1))
write_tab(calib, "c3_05_calib_bias.csv")

# Run length needed for |bias| <= p% of pi_cold (fitted, as c3_04): the
# relative tolerance p is delta = (p / 100) * mu_pi / SD_pi in SD units.
calib_T <- bind_rows(parallel::mclapply(unique(tmap$var), mc.cores = N_CORES,
  function(v) {
    y <- Yc[[v]]
    pm <- pi_moments(y, pi_rows)
    d_pct <- PCT_TOL / 100 * abs(pm$mu) / sqrt(pm$s2)
    g <- function(yy) cold_times(yy, fit_t, pi_rows, 0.1, d_pct)$t_mean
    est <- g(y)
    ci <- boot_ci(do.call(rbind, lapply(seq_len(N_BOOT_FIT), function(b) {
      g(y[, sample.int(n_c, n_c, replace = TRUE)])
    })))
    tibble(var = v, tol_pct = PCT_TOL, delta_sd = d_pct, T_run = est,
      lo = ci[, 1], hi = ci[, 2])
  }))
write_tab(calib_T, "c3_05_calib_run_length.csv")

# (b) Research outcomes of runs started at year B (C3-M4) --------------------------
# A run restarted from the state at the end of year B covers years B + 1 ...
# Outcomes as in outcomes.R / c2_config.R, and 20-year windows as cycle 1:
#   cml_*     : HIV infections summed over years B + INT_B + 1 ... B + INT_END
#   *_y15     : value in year B + INT_END
#   M20_*     : mean over years B + 1 ... B + WINDOW_L
# Reference: the same functional over every window starting at a year >=
# LATE_START (annual values: years >= LATE_START), global mean.
B_grid <- 0:250
f_def <- c(
  lapply(c("", ".B", ".H", ".W"), function(g) {
    list(name = paste0("cml_incid", g), var = paste0("hiv.incid", g),
      type = "sum", lead = INT_B, L = INT_L)
  }),
  list(list(name = "incid_rate_y15", var = "incid_rate", type = "value",
    lead = INT_END, L = 1)),
  lapply(c("prev", "i.prev.dx.B", "i.prev.dx.H", "i.prev.dx.W"), function(v) {
    list(name = paste0(v, "_y15"), var = v, type = "value", lead = INT_END,
      L = 1)
  }),
  lapply(c("prev", "incid_rate", "dx_frac", "supp_frac", "prep_cov",
    "gono_prev", "chla_prev", "syph_prev", "num"), function(v) {
      list(name = paste0("M20_", v), var = v, type = "mean", lead = 0,
        L = WINDOW_L)
    })
)
names(f_def) <- vapply(f_def, `[[`, character(1), "name")

#' Per-chain values of a functional for each B (W) and over the reference
#' windows (R), so that chain bootstraps only resample columns
fun_values <- function(y, f) {
  if (f$type == "value") {
    return(list(W = y[B_grid + f$lead, , drop = FALSE],
      R = y[pi_rows, , drop = FALSE]))
  }
  fun <- if (f$type == "sum") "sum" else "mean"
  starts <- seq(LATE_START, nrow(y) - f$L + 1)
  list(W = window_from_x0(y, f$L, B_grid + f$lead, fun),
    R = window_from_x0(y, f$L, starts - 1, fun))
}
fun_stats <- function(W, R) {
  mu <- mean(R)
  v <- mean((R - mu)^2)
  m <- rowMeans(W)
  c(o = (m - mu) / sqrt(v), pct = 100 * (m / mu - 1),
    r = apply(W, 1, var) / v)
}
#' 20-year windows: within-window variance ratio and mean change over the
#' window (OLS slope x L) in SD_pi units, against the reference windows
win_extra <- function(y) {
  w <- window_funs(y, WINDOW_L, B_grid)
  wr <- window_funs(y, WINDOW_L, seq(LATE_START, nrow(y) - WINDOW_L + 1) - 1)
  list(S2 = w$S2, S2r = wr$S2, slope = w$slope,
    sd_y = sqrt(pi_moments(y, pi_rows)$s2))
}
extra_stats <- function(e, i) {
  c(s2 = rowMeans(e$S2[, i, drop = FALSE]) / mean(e$S2r[, i]),
    trend = rowMeans(e$slope[, i, drop = FALSE]) * WINDOW_L / e$sd_y)
}

nb <- length(B_grid)
run_start <- function(Y, label) {
  n <- ncol(Y[[1]])
  bind_rows(parallel::mclapply(f_def, mc.cores = N_CORES, function(f) {
    fv <- fun_values(Y[[f$var]], f)
    est <- fun_stats(fv$W, fv$R)
    ci <- boot_ci(chain_boot(n, N_BOOT, function(i) {
      fun_stats(fv$W[, i, drop = FALSE], fv$R[, i, drop = FALSE])
    }))
    out <- tibble(start = label, fun = f$name, B = B_grid,
      o = est[1:nb], o_lo = ci[1:nb, 1], o_hi = ci[1:nb, 2],
      pct = est[nb + 1:nb], pct_lo = ci[nb + 1:nb, 1],
      pct_hi = ci[nb + 1:nb, 2],
      r = est[2 * nb + 1:nb], r_lo = ci[2 * nb + 1:nb, 1],
      r_hi = ci[2 * nb + 1:nb, 2])
    if (f$type == "mean") {
      e <- win_extra(Y[[f$var]])
      est_e <- extra_stats(e, seq_len(n))
      ci_e <- boot_ci(chain_boot(n, N_BOOT, function(i) {
        extra_stats(list(S2 = e$S2, S2r = e$S2r, slope = e$slope,
          sd_y = sqrt(pi_moments(Y[[f$var]][, i], pi_rows)$s2)), i)
      }))
      out <- mutate(out,
        s2_ratio = est_e[1:nb], s2_lo = ci_e[1:nb, 1], s2_hi = ci_e[1:nb, 2],
        trend_sd = est_e[nb + 1:nb], trend_lo = ci_e[nb + 1:nb, 1],
        trend_hi = ci_e[nb + 1:nb, 2])
    }
    out
  }))
}
win <- bind_rows(run_start(Yc, "cold start"), run_start(Yx, "x0 restart"))
write_tab(win, "c3_05_research_windows.csv")

# Burn-in needed for the research outcomes -----------------------------------------
# Fitted offset curve o_W(B) over B = 0-250 (tail window, as c3_04), then
# the B after which |o_W| stays <= delta: 0.1 and 0.2 SD, the MCSE criterion
# 0.2 / sqrt(N) for N = 32 (runs per scenario) and 256, and 1% of the
# outcome level. CIs: bootstrap refits.
d_mcse <- MCSE_FRAC / sqrt(c(32, 256))
B_needed <- function(Y, label) {
  n <- ncol(Y[[1]])
  bind_rows(parallel::mclapply(f_def, mc.cores = N_CORES, function(f) {
    fv <- fun_values(Y[[f$var]], f)
    g <- function(i) {
      s <- fun_stats(fv$W[, i, drop = FALSE], fv$R[, i, drop = FALSE])
      o <- s[1:nb]
      R <- fv$R[, i, drop = FALSE]
      d1 <- 0.01 * abs(mean(R)) / sqrt(mean((R - mean(R))^2))
      ta <- tail_start(B_grid, o, TAIL_LEVEL)
      k <- B_grid >= ta
      fm <- fit_mean_relax_c3(B_grid[k], o[k])
      vapply(c(DELTA_C3, d_mcse, d1), function(d) {
        t_tol(B_grid, o, fm, ta, d)
      }, numeric(1))
    }
    est <- g(seq_len(n))
    ci <- boot_ci(do.call(rbind, lapply(seq_len(N_BOOT_FIT), function(b) {
      g(sample.int(n, n, replace = TRUE))
    })))
    tibble(start = label, fun = f$name,
      tolerance = c(paste0(DELTA_C3, " SD"), paste0("0.2 MCSE, N = ",
        c(32, 256)), "1% of level"),
      B = est, lo = ci[, 1], hi = ci[, 2])
  }))
}
bneed <- bind_rows(B_needed(Yc, "cold start"), B_needed(Yx, "x0 restart"))
write_tab(bneed, "c3_05_burnin_needed.csv")
print(as.data.frame(bneed |> filter(tolerance == "0.1 SD")))

# Summary at the burn-ins of interest -------------------------------------------------
# B = 0: research runs started at the origin (x0 = current single restart
# point); B = 70: states saved after the production burn-in (the pool).
sum_tab <- win |>
  filter(B %in% c(0, 30, 50, 70, 100, 150)) |>
  transmute(start, fun, B,
    offset_sd = fmt_ci(o, o_lo, o_hi), offset_pct = fmt_ci(pct, pct_lo, pct_hi),
    var_ratio = fmt_ci(r, r_lo, r_hi),
    s2_ratio = ifelse(is.na(s2_ratio), NA, fmt_ci(s2_ratio, s2_lo, s2_hi)),
    trend_sd = ifelse(is.na(trend_sd), NA, fmt_ci(trend_sd, trend_lo,
      trend_hi)))
write_tab(sum_tab, "c3_05_research_summary.csv")

# Figures ----------------------------------------------------------------------
show <- c("cml_incid", "cml_incid.B", "cml_incid.H", "cml_incid.W",
  "incid_rate_y15", "prev_y15", "i.prev.dx.B_y15", "M20_prev", "M20_dx_frac",
  "M20_gono_prev", "M20_chla_prev", "M20_num")
p <- win |>
  filter(fun %in% show) |>
  mutate(fun = factor(fun, show)) |>
  ggplot(aes(B, o, colour = start, fill = start)) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = c(-0.1, 0.1), linetype = 3) +
  geom_ribbon(aes(ymin = o_lo, ymax = o_hi), alpha = 0.2, colour = NA) +
  geom_line(linewidth = 0.4) +
  geom_vline(xintercept = PROD_BURNIN, linetype = 2, colour = "grey40") +
  facet_wrap(~fun, ncol = 4, scales = "free_y") +
  coord_cartesian(ylim = c(-2, 3)) +
  labs(x = "Age B of the restart state (years since the start)",
    y = "Offset of the mean outcome (SD_pi of the outcome)",
    colour = NULL, fill = NULL,
    title = "Research outcomes of runs started from states of age B",
    subtitle = paste0("Each experiment against its own pi. Dotted: +-0.1 ",
      "SD. Dashed: B = 70 (production burn-in). Clipped at -2 / +3 SD.")) +
  theme(legend.position = "bottom")
save_fig(p, "c3_05_research_offset.png", 13, 10)

p <- win |>
  filter(fun %in% show) |>
  mutate(fun = factor(fun, show)) |>
  ggplot(aes(B, r, colour = start, fill = start)) +
  geom_hline(yintercept = 1) +
  geom_hline(yintercept = 0.9, linetype = 3) +
  geom_ribbon(aes(ymin = r_lo, ymax = r_hi), alpha = 0.2, colour = NA) +
  geom_line(linewidth = 0.4) +
  geom_vline(xintercept = PROD_BURNIN, linetype = 2, colour = "grey40") +
  facet_wrap(~fun, ncol = 4) +
  coord_cartesian(ylim = c(0, 1.6)) +
  labs(x = "Age B of the restart state (years since the start)",
    y = "Variance across runs / stationary variance", colour = NULL,
    fill = NULL,
    title = "Spread of the research outcomes of runs started at age B",
    subtitle = paste0("x0 runs share one start, so B = 0 is the single-point ",
      "design; cold-start runs are independent.")) +
  theme(legend.position = "bottom")
save_fig(p, "c3_05_research_var_ratio.png", 13, 10)

p <- calib |>
  filter(run_years <= 150) |>
  ggplot(aes(run_years, bias_pct)) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = c(-1, 1), linetype = 3) +
  geom_errorbar(aes(ymin = bias_pct_lo, ymax = bias_pct_hi), width = 3) +
  geom_point() +
  geom_line() +
  geom_vline(xintercept = PROD_BURNIN, linetype = 2, colour = "grey40") +
  facet_wrap(~target, scales = "free_y", ncol = 5) +
  labs(x = "Length of the cold-start run (years)",
    y = "Bias of the target in the last year vs pi_cold (%)",
    title = "Ballpark calibration from a cold start: bias of each target",
    subtitle = "Dotted: +-1%. Dashed: 70 years (calibration_end).")
save_fig(p, "c3_05_calib_bias.png", 14, 10)

save_session("c3_05")
