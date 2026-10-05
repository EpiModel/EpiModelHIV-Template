# =============================================================================
# c5_01_prepare.R
# Question : Do the scenario runs have the intended design (32 points x 4
#            runs per scenario, pool points identified), and did each
#            scenario's parameter change take effect at the intended time?
# Inputs   : data/run/variance_scenarios/{short,long}/merged_tibbles/*.rds,
#            data/run/estimates/restart_pool.rds,
#            data/run/restart_assessment/cycle4/c4_01_annual_pool.rds,
#            R/C-new_calibration/workflow-variance_scenarios.R
# Outputs  : data/run/restart_assessment/cycle5/c5_01_annual_{short,long}.rds,
#            cycle5/results/tables/c5_01_*.csv, figures/c5_01_*.png
# Method   : c5_METHODS.md C5-M1; results/c5_01_prepare.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle5/c5_config.R")
source("R/E-restart_assessment/cycle5/c5_utils.R")
set.seed(SEED)

# Dictionary, variable kinds and the pool states (as cycle 4) ----------------------
c4 <- readRDS(POOL_ANNUAL_PATH)
dict <- c4$dict
kind <- c4$kind
rp <- readRDS(POOL_RESTART)
stopifnot(length(rp$run) == N_POINTS_C5)
pool_epi <- vapply(names(rp$epi), function(v) {
  as.numeric(unlist(rp$epi[[v]][1, ]))
}, numeric(length(rp$run)))
rm(rp)

# Short runs -----------------------------------------------------------------------
short <- lapply(names(SHORT_FILES), function(s) {
  d <- readRDS(fs::path(SC_DIR, "short", "merged_tibbles", SHORT_FILES[[s]]))
  a <- annual_scenario(d, SHORT_YEARS, pool_epi, dict, kind)
  rm(d)
  gc()
  a
})
names(short) <- names(SHORT_FILES)

# Long runs (S4) and their baseline: the cycle 4 pool runs, first 150 years ------
d <- readRDS(fs::path(SC_DIR, "long", "merged_tibbles", LONG_FILE))
s4 <- annual_scenario(d, LONG_YEARS, pool_epi, dict, kind)
rm(d)
gc()
base_long <- list(
  Y = lapply(c4$Y, function(m) m[seq_len(LONG_YEARS), , drop = FALSE]),
  point = c4$point, sim = c4$sims
)
# pi of the baseline: cycle 4 years >= LATE_START (c4_03: pi_pool = pi_cold)
pi_base <- lapply(c4$Y, function(m) pi_moments(m, LATE_START:N_YEARS))

# Design ---------------------------------------------------------------------------------
design <- bind_rows(
  lapply(names(short), function(s) {
    tibble(set = "short", scenario = s, runs = length(short[[s]]$point),
      points = n_distinct(short[[s]]$point),
      min_per_point = min(table(short[[s]]$point)),
      max_per_point = max(table(short[[s]]$point)), years = SHORT_YEARS)
  }),
  tibble(set = "long", scenario = "s4_acts", runs = length(s4$point),
    points = n_distinct(s4$point), min_per_point = min(table(s4$point)),
    max_per_point = max(table(s4$point)), years = LONG_YEARS),
  tibble(set = "long", scenario = "baseline (cycle 4 runs)",
    runs = length(base_long$point), points = n_distinct(base_long$point),
    min_per_point = min(table(base_long$point)),
    max_per_point = max(table(base_long$point)), years = LONG_YEARS)
)
write_tab(design, "c5_01_design.csv")
print(design)
stopifnot(all(design$points == N_POINTS_C5),
  all(design$min_per_point[design$scenario != "baseline (cycle 4 runs)"] == N_PER_ARM),
  all(design$max_per_point[design$scenario != "baseline (cycle 4 runs)"] == N_PER_ARM))

# Did the changes take effect? --------------------------------------------------------
# Mean of the variable each scenario acts on, over years 1-5 (before the
# change) and 6-15 (after), by arm. Before the change every arm has the
# baseline parameters, so the means must agree within chance.
mech <- c(dx_per_year = "hiv.dx.incid", undiagnosed = "undx",
  prep_cov = "prep_cov", gono_ir = "gono_ir", chla_ir = "chla_ir",
  syph_ir = "syph_ir", prev = "prev")
arm_period <- bind_rows(lapply(names(short), function(s) {
  Y <- short[[s]]$Y
  Y$undx <- Y$hiv.inf - Y$hiv.dx
  bind_rows(lapply(names(mech), function(m) {
    y <- Y[[mech[[m]]]]
    tibble(scenario = s, variable = m,
      years_1_5 = mean(y[1:INT_B, ]), years_6_15 = mean(y[(INT_B + 1):SHORT_YEARS, ]),
      se_1_5 = sd(colMeans(y[1:INT_B, ])) / sqrt(ncol(y)))
  }))
}))
base_ref <- arm_period |> filter(scenario == "baseline") |>
  select(variable, b_1_5 = years_1_5, b_6_15 = years_6_15)
arm_period <- arm_period |> left_join(base_ref, by = "variable") |>
  mutate(z_before = (years_1_5 - b_1_5) / (sqrt(2) * se_1_5),
    change_after_pct = 100 * (years_6_15 / b_6_15 - 1))
write_tab(arm_period, "c5_01_mechanism_check.csv")
print(as.data.frame(arm_period |> select(scenario, variable, z_before, change_after_pct)))

# The parameter values that were set, from the workflow script ---------------------
wf_lines <- readLines(WF_SC_SCRIPT)
write_tab(tibble(line = grep("apply_or\\(param|acts.scale|intervention_start,",
  wf_lines, value = TRUE)), "c5_01_scenario_definitions.csv")

# Initial state of each point (for the heterogeneity predictors, c5_03, c5_04) ---
pe <- as.data.frame(pool_epi)
point_state <- tibble(
  point = seq_len(N_POINTS_C5),
  prev = pe$hiv.inf / pe$num,
  undx_frac = (pe$hiv.inf - pe$hiv.dx) / pe$num,
  dx_frac = pe$hiv.dx / pe$hiv.inf,
  prep_cov = pe$prep / pe$prep.indic,
  gono_prev = pe$gono.inf / pe$num,
  chla_prev = pe$chla.inf / pe$num,
  syph_prev = pe$syph.inf / pe$num,
  num = pe$num
)
write_tab(point_state, "c5_01_point_state.csv")

# Save ---------------------------------------------------------------------------------
saveRDS(list(arms = short, dict = dict, point_state = point_state,
  pi_base = pi_base), SHORT_ANNUAL_PATH)
saveRDS(list(s4 = s4, base = base_long, dict = dict, point_state = point_state,
  pi_base = pi_base), LONG_ANNUAL_PATH)

# Figures ------------------------------------------------------------------------------
traj <- bind_rows(lapply(names(short), function(s) {
  Y <- short[[s]]$Y
  bind_rows(lapply(c("prev", "incid_rate", "dx_frac", "prep_cov", "gono_ir",
    "syph_ir"), function(v) {
    tibble(scenario = s, var = v, year = seq_len(SHORT_YEARS),
      mean = rowMeans(Y[[v]]))
  }))
}))
p <- ggplot(traj, aes(year, mean, colour = scenario)) +
  geom_vline(xintercept = INT_B + 0.5, linetype = 2, colour = "grey50") +
  geom_line() + facet_wrap(~var, scales = "free_y") +
  labs(x = "Year after the restart", y = "Mean over 128 runs",
    title = "Short scenario runs: mean trajectories",
    subtitle = "Dashed line: the change at step 262 (start of year 6)")
save_fig(p, "c5_01_short_trajectories.png")

lt <- bind_rows(
  tibble(arm = "S4 (acts x 0.9)", year = seq_len(LONG_YEARS),
    prev = rowMeans(s4$Y$prev)),
  tibble(arm = "baseline (cycle 4 runs)", year = seq_len(LONG_YEARS),
    prev = rowMeans(base_long$Y$prev))
)
p <- ggplot(lt, aes(year, prev, colour = arm)) + geom_line() +
  labs(x = "Year after the restart", y = "Mean HIV prevalence",
    title = "S4: 10% fewer acts from the restart, against the baseline")
save_fig(p, "c5_01_long_prevalence.png")

save_session("c5_01")
