# =============================================================================
# c2_01_provenance.R
# Question : Where does the restart state x0 come from, was it produced with
#            the same model parameters as the variance runs, does the restart
#            itself create a discontinuity, and how does the stationary law
#            of the variance runs compare with the calibration targets?
# Inputs   : data/run/estimates/restart-*.rds, restart_pool.rds,
#            data/input/model_parameters.csv, the weekly variance data,
#            data/run/restart_assessment/01_annual.rds (cycle 1)
# Outputs  : cycle2/results/tables/c2_01_*.csv, figures/c2_01_*.png
# Method   : c2_METHODS.md C2-M0, C2-M1; results/c2_01_provenance.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle2/c2_config.R")
source("R/E-restart_assessment/cycle2/c2_utils.R")
set.seed(SEED)

# Which restart file is x0? ----------------------------------------------------
# x0 = the first recorded row, identical in all chains (cycle 1, step 01)
inv <- read.csv(fs::path(C1_TAB_DIR, "01_raw_inventory.csv"))
x0 <- setNames(inv$x0, inv$name)
match_vars <- c("num", "num.B", "num.H", "num.W", "hiv.inf", "hiv.dx",
  "hiv.tx", "hiv.supp", "prep", "prep.indic", "gono.inf", "chla.inf",
  "syph.inf")
restart_files <- fs::dir_ls(est_dir, regexp = "restart.*\\.rds$")
src <- bind_rows(lapply(restart_files, function(f) {
  r <- readRDS(f)
  m <- vapply(match_vars, function(v) {
    e <- r$epi[[v]]
    as.numeric(unlist(e[nrow(e), ]))
  }, numeric(r$control$nsims))
  m <- matrix(m, nrow = r$control$nsims)
  dist <- rowSums(abs(sweep(m, 2, x0[match_vars])))
  tibble(
    file = fs::path_file(f),
    modified = as.character(fs::file_info(f)$modification_time),
    nsims = r$control$nsims,
    best_sim = which.min(dist),
    abs_distance = min(dist),
    exact_match = min(dist) == 0
  )
}))
write_tab(src, "c2_01_x0_source.csv")
print(src)
x0_file <- src$file[src$exact_match][1]
stopifnot(!is.na(x0_file))

# Parameters of x0 vs parameters of the variance runs ------------------------
# The restart object keeps the `param` list it was simulated with. Vector
# parameters appear in the csv as name_1, name_2, ...
r0 <- readRDS(fs::path(est_dir, x0_file))
p_old <- r0$param
cur <- read.csv(fs::path(input_dir, "model_parameters.csv"))
get_old <- function(nm) {
  if (!is.null(p_old[[nm]])) return(as.character(p_old[[nm]][1]))
  m <- regmatches(nm, regexec("^(.*)_([0-9]+)$", nm))[[1]]
  if (length(m) == 3 && !is.null(p_old[[m[2]]])) {
    v <- p_old[[m[2]]]
    i <- as.integer(m[3])
    if (i <= length(v)) return(as.character(v[i]))
  }
  NA_character_
}
pdiff <- cur |>
  transmute(
    param,
    value_variance_runs = value,
    value_x0 = vapply(param, get_old, character(1)),
    rel_diff = suppressWarnings(
      (as.numeric(value) - as.numeric(value_x0)) / abs(as.numeric(value_x0))),
    relevant.calibration.target
  ) |>
  mutate(differs = is.na(value_x0) | (!is.na(rel_diff) & abs(rel_diff) > 0.01))
write_tab(pdiff, "c2_01_param_diff_all.csv")
write_tab(filter(pdiff, differs), "c2_01_param_diff.csv")
cat("Parameters that differ (> 1% or absent in x0):", sum(pdiff$differs),
  "of", nrow(pdiff), "\n")
# parameters present in x0 but absent from the current csv
extra <- setdiff(names(p_old), c(cur$param,
  unique(sub("_[0-9]+$", "", cur$param))))
write_tab(tibble(param_only_in_x0 = extra), "c2_01_param_only_in_x0.csv")
rm(r0)

# Continuity at the restart (weekly data) ------------------------------------
# A restart artifact (e.g. a reset timer or lost history) shows as a jump in
# the first simulated week that is out of line with the following weeks. A
# smooth transient (e.g. a parameter change) does not. For each variable, the
# cross-chain mean at week k after restart (k = 0 is the copied x0 row) is
# compared with weeks 2-26:
#   stocks: first weekly increment vs the increments of weeks 2-26
#   flows : first-week level vs the levels of weeks 2-26
# z = (first - median) / MAD. The x0 row of flows is the last week of the run
# that produced x0 (old parameters), so F0 vs F1 shows the immediate effect of
# the parameter change.
d <- readRDS(DATA_PATH) |>
  select(-batch_number, -sim_number) |>
  filter(!(sim %in% DROP_SIMS), time <= min(time) + 52)
raw_vars <- setdiff(names(d), c("sim", "time"))
kind <- ifelse(grepl("incid|^arrivals|^departures|^nNew$", raw_vars),
  "flow", "stock")
wk <- d |>
  mutate(week = time - min(time)) |>
  summarise(across(all_of(raw_vars), mean), .by = week) |>
  arrange(week)
rm(d)
cont <- bind_rows(lapply(seq_along(raw_vars), function(i) {
  v <- raw_vars[i]
  kd <- kind[i]
  y <- wk[[v]]
  if (kd == "stock") {
    inc <- diff(y) # inc[k] = y[k] - y[k - 1], k = 1..52
    ref <- inc[2:26]
    first <- inc[1]
  } else {
    ref <- y[3:27] # weeks 2..26
    first <- y[2]  # week 1
  }
  s <- mad(ref)
  tibble(
    var = v, kind = kd,
    x0_row = y[1], week1 = y[2], median_wk2_26 = median(y[3:27]),
    first_stat = first, ref_median = median(ref), ref_mad = s,
    z_first = if (s > 0) (first - median(ref)) / s else NA_real_,
    flow_x0_vs_wk2_26_pct = if (kd == "flow")
      100 * (y[1] / median(y[3:27]) - 1) else NA_real_
  )
}))
write_tab(cont, "c2_01_restart_continuity.csv")
print(as.data.frame(cont |> arrange(desc(abs(z_first))) |> head(12)))

p <- wk |>
  tidyr::pivot_longer(-week) |>
  filter(name %in% c("hiv.inf", "hiv.incid", "hiv.dx", "prep", "prep.indic",
    "gono.inf", "gono.incid", "chla.inf", "chla.incid", "syph.inf",
    "syph.incid", "num")) |>
  mutate(value = value / value[week == 0], .by = name) |>
  ggplot(aes(week, value)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_line() +
  geom_point(size = 0.6) +
  facet_wrap(~name, scales = "free_y") +
  labs(x = "Weeks after restart (0 = copied x0 row)",
    y = "Cross-chain mean / value at x0",
    title = "First year after the restart, weekly cross-chain means")
save_fig(p, "c2_01_first_year_weekly.png", 12, 8)

# Stationary law of the variance runs vs calibration targets ------------------
annual <- readRDS(ANNUAL_PATH)
Y <- add_project_vars(annual$Y)
pi_rows <- LATE_START:N_YEARS
targets <- EpiModelHIV::get_calibration_targets()
tv <- targets[names(targets) %in% names(target_map)]
tt <- bind_rows(lapply(names(tv), function(tn) {
  v <- target_map[[tn]]
  y <- Y[[v]]
  pm <- pi_moments(y, pi_rows)
  h70 <- y[CALIB_H, ]
  tibble(
    target = tn, variable = v, target_value = tv[[tn]],
    pi_mean = pm$mu, pi_sd = sqrt(pm$s2),
    z_target = (tv[[tn]] - pm$mu) / sqrt(pm$s2),
    rel_gap_pct = 100 * (pm$mu / tv[[tn]] - 1),
    x0_run_mean_h70 = mean(h70), x0_run_sd_h70 = sd(h70),
    z_h70 = (mean(h70) - pm$mu) / sqrt(pm$s2)
  )
}))
write_tab(tt, "c2_01_targets_vs_pi.csv")
print(as.data.frame(tt))

save_session("c2_01")
