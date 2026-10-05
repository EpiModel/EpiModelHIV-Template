# =============================================================================
# c4_01_prepare.R
# Question : How were the pool runs made: which states are the 32 restart
#            points, how many runs start from each, with which parameters and
#            network coefficients? Which annual dataset and which
#            restart-continuity data do the later steps use?
# Inputs   : data/run/variance/df__variance_long_pool.rds (weekly),
#            data/run/variance/df__variance_long_x0.rds (cold start, weekly),
#            data/run/estimates/restart_pool.rds, netest-hpc.rds,
#            workflows/variance_assess_pool/SWF/steps/2/map.rds,
#            workflows/variance_assess_raw/SWF/steps/2/map.rds,
#            cycle 3 annual data and tables (read-only)
# Outputs  : cycle4/results/tables/c4_01_*.csv, figures/c4_01_*.png,
#            data/run/restart_assessment/cycle4/c4_01_annual_pool.rds
# Method   : c4_METHODS.md C4-M0, C4-M1; results/c4_01_prepare.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle4/c4_config.R")
source("R/E-restart_assessment/cycle4/c4_utils.R")
set.seed(SEED)

# Run inputs (C4-M0) ---------------------------------------------------------------
# The exact netsim inputs shipped to the HPC, and the parameter list compared
# element by element with the one of the cold-start runs (cycle 3).
wf <- readRDS(WF_POOL_MAP)$MoreArgs
wf3 <- readRDS(WF_MAP_PATH)$MoreArgs
setup <- tibble(
  item = c("path_to_x", "nsteps", "start", "randomize.restart",
    "initialize.FUN is EpiModel::initialize.net", "resimulate.network",
    "n_rep", "n_batch", "n_cores"),
  value = c(as.character(wf$path_to_x), wf$control$nsteps, wf$control$start,
    wf$control$randomize.restart,
    identical(deparse(wf$control$initialize.FUN),
      deparse(EpiModel::initialize.net)),
    wf$control$resimulate.network, wf$n_rep, wf$n_batch, wf$n_cores)
)
write_tab(setup, "c4_01_run_setup.csv")
nm <- union(names(wf$param), names(wf3$param))
pcmp <- tibble(param = nm,
  identical_to_cold_runs = vapply(nm, function(n) {
    identical(wf$param[[n]], wf3$param[[n]])
  }, logical(1)))
write_tab(pcmp, "c4_01_param_compare.csv")
cat("Parameters identical to the cold-start runs:", sum(pcmp$identical_to_cold_runs),
  "of", nrow(pcmp), "\n")
rm(wf, wf3)

# The restart pool and its network coefficients (C3-M0) -------------------------
# Offset of each point's edges coefficients against the local netest, as in
# cycle 3: coef - c0 - log(N_init / N). A point saved from a run started
# from this netest, with a consistent population correction, has offset 0.
rp <- readRDS(POOL_RESTART)
net_local <- readRDS(fs::path(est_dir, "netest-hpc.rds"))
c0 <- vapply(net_local, function(x) unname(x$coef.form[1]), numeric(1))
n_init <- network::network.size(net_local[[1]]$newnetwork)
rm(net_local)
cf <- t(vapply(rp$coef.form[seq_along(rp$run)], function(x) {
  vapply(x, function(y) unname(y[1]), numeric(1))
}, numeric(length(c0))))
n_pt <- vapply(rp$run, function(x) as.numeric(x$num), numeric(1))
off <- sweep(cf, 2, c0) - log(n_init / n_pt)
net_tab <- bind_rows(
  tibble(source = "pool of the cycle 4 runs (restart_pool.rds, 2026-09-27)",
    file = "restart_pool.rds", network = names(c0), netest_coef_local = c0,
    n_points = nrow(cf), offset_min = apply(off, 2, min),
    offset_max = apply(off, 2, max),
    tie_propensity_ratio = exp(colMeans(off)),
    num_elig_saved = !is.null(rp$run[[1]]$num.elig)),
  read.csv(fs::path(C3_TAB_DIR, "c3_01_network_coefs.csv"))
)
write_tab(net_tab, "c4_01_network_coefs.csv", 6)
print(as.data.frame(net_tab))
pool_time <- vapply(rp$run, function(x) as.numeric(x$current_timestep),
  numeric(1))
# the saved state of each point: [point, variable]
pool_epi <- vapply(names(rp$epi), function(v) {
  as.numeric(unlist(rp$epi[[v]][1, ]))
}, numeric(length(rp$run)))
rm(rp)

# Load the pool runs ---------------------------------------------------------------
d <- readRDS(POOL_PATH)
cat("Class:", class(d), "\nDim:", dim(d), "\nSize:",
  format(object.size(d), units = "GB"), "\n")
d <- select(d, -batch_number, -sim_number)
o <- order(d$sim, d$time)
if (!identical(o, seq_along(o))) d <- d[o, ]
rm(o)
sims <- sort(unique(d$sim))
steps <- sort(unique(d$time))
n_sim <- length(sims)
stopifnot(
  length(steps) == N_YEARS * year_steps, min(steps) == restart_time,
  all(table(d$sim) == length(steps)),
  !anyNA(d)
)
raw_vars <- setdiff(names(d), c("sim", "time"))
kind <- ifelse(grepl("incid|^arrivals|^departures|^nNew$", raw_vars),
  "flow", "stock")
common <- intersect(raw_vars, colnames(pool_epi))

# Restart point of each run (C4-M1) ------------------------------------------------
# The first recorded row of a restarted run is the copied state, so it
# identifies the point even though randomize.restart drew it at random.
first <- d[d$time == min(steps), c("sim", raw_vars)]
P <- t(pool_epi[, common, drop = FALSE])
point <- vapply(seq_len(nrow(first)), function(i) {
  hit <- which(colSums(abs(P - unlist(first[i, common]))) == 0)
  if (length(hit) == 1) hit else NA_integer_
}, integer(1))
stopifnot(!anyNA(point))
n_runs <- tabulate(point, nrow(pool_epi))
runs_pp <- tibble(point = seq_len(nrow(pool_epi)), n_runs = n_runs)
stopifnot(sum(runs_pp$n_runs) == n_sim)
write_tab(runs_pp, "c4_01_runs_per_point.csv")
write_tab(tibble(k_points = nrow(runs_pp), N_runs = n_sim,
  min_runs = min(n_runs), max_runs = max(n_runs),
  points_with_one_run = sum(n_runs == 1),
  sum_n2_over_N = sum(n_runs^2) / n_sim,
  balanced_value = n_sim / nrow(runs_pp)), "c4_01_design.csv")
cat("Runs per point:", paste(runs_pp$n_runs, collapse = " "), "\n")

# Absorbing events -------------------------------------------------------------------
extinct <- d |>
  summarise(
    across(c(syph.inf, gono.inf, chla.inf, hiv.inf),
      ~ if (any(.x == 0)) (min(time[.x == 0]) - 2) / year_steps else NA_real_
    ),
    .by = sim
  ) |>
  filter(if_any(-sim, ~ !is.na(.x)))
write_tab(extinct, "c4_01_extinctions_year.csv")
print(extinct)

# Seam data and the first simulated year (C4-M3) ------------------------------------
# Weeks 0 ... N_WEEKS_SEAM after the restart (week 0 = the copied state), and
# the first 52 simulated weeks (steps 3 ... 54) of every run.
seam_pool <- d |>
  filter(time <= min(steps) + N_WEEKS_SEAM) |>
  mutate(week = time - min(steps), point = point[match(sim, first$sim)])
fy_raw <- d |>
  filter(time >= min(steps) + 1, time <= min(steps) + year_steps) |>
  summarise(
    across(all_of(raw_vars[kind == "flow"]), sum),
    across(all_of(raw_vars[kind == "stock"]), mean),
    .by = sim
  ) |>
  arrange(sim)

# Annual aggregation (M1.2) -----------------------------------------------------------
# Year k covers steps (k - 1) * 52 + 2 ... k * 52 + 1, as for the x0 runs.
annual_raw <- setNames(lapply(seq_along(raw_vars), function(i) {
  annualise(d[[raw_vars[i]]], kind[i], N_YEARS, n_sim)
}), raw_vars)
rm(d)
gc()

# Source of the points: final states of cold-start runs (C4-M1) -------------------
dc <- readRDS(COLD_PATH) |> select(-batch_number, -sim_number)
t_end <- max(dc$time)
last <- dc[dc$time == t_end, c("sim", common)]
L <- t(as.matrix(last[, common]))
src <- vapply(seq_len(nrow(pool_epi)), function(j) {
  hit <- which(colSums(abs(L - pool_epi[j, common])) == 0)
  if (length(hit) == 1) last$sim[hit] else NA_real_
}, numeric(1))
stopifnot(!anyNA(src))
seam_src <- dc |>
  filter(sim %in% src, time >= t_end - N_WEEKS_SEAM) |>
  mutate(week = time - t_end, point = match(sim, src))
rm(dc, last, L)
gc()
write_tab(tibble(point = seq_along(src), source_cold_sim = src,
  source_timestep = pool_time, n_runs = runs_pp$n_runs), "c4_01_point_source.csv")

# Derived variables and dictionary --------------------------------------------------
cold <- readRDS(COLD_ANNUAL_PATH)
dict <- cold$dict
pi_cold <- vapply(dict$name[dict$block == "key"], function(v) {
  mean(cold$Y[[v]][LATE_START:N_YEARS, ])
}, numeric(1))
rm(cold)
Y <- add_project_vars_c3(c(derive_vars(annual_raw), annual_raw))
fy_list <- lapply(fy_raw[raw_vars], function(x) matrix(x, nrow = 1))
FY <- add_project_vars_c3(c(derive_vars(fy_list), fy_list))
stopifnot(all(dict$name %in% names(Y)))

annual <- list(
  Y = Y[dict$name],
  sims = sims,
  point = point,
  n_per_point = runs_pp$n_runs,
  source_sim = src,
  years = seq_len(N_YEARS),
  dict = dict,
  first_year = lapply(FY[dict$name], as.vector),
  seam_pool = seam_pool,
  seam_src = seam_src,
  kind = setNames(kind, raw_vars)
)
saveRDS(annual, POOL_ANNUAL_PATH)
cat("Annual object size:", format(object.size(annual), units = "MB"), "\n")

# Figures ------------------------------------------------------------------------------
key <- dict$name[dict$block == "key"]
show <- sample(n_sim, 10)
band <- bind_rows(lapply(key, function(v) {
  tibble(var = v, year = annual$years, mean = rowMeans(Y[[v]]),
    q05 = apply(Y[[v]], 1, quantile, 0.05),
    q95 = apply(Y[[v]], 1, quantile, 0.95))
}))
chains <- bind_rows(lapply(key, function(v) {
  tibble(var = v, year = rep(annual$years, 10),
    chain = rep(show, each = N_YEARS), value = as.vector(Y[[v]][, show]))
}))
p <- ggplot(band, aes(year)) +
  geom_line(data = chains, aes(y = value, group = chain), alpha = 0.25,
    linewidth = 0.2) +
  geom_ribbon(aes(ymin = q05, ymax = q95), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = mean), colour = "steelblue4") +
  geom_hline(data = tibble(var = key, value = pi_cold[key]),
    aes(yintercept = value), colour = "red", linetype = 2) +
  facet_wrap(~var, scales = "free_y", ncol = 4) +
  labs(x = "Years after the restart", y = NULL,
    title = "Key variables, runs from the 32-point pool: 10 runs, mean, 5-95% band",
    subtitle = "Red dashed: stationary mean of the cold-start runs (cycle 3)")
save_fig(p, "c4_01_key_600y.png", 14, 16)

# Runs from the same point diverge: prevalence of every run from 6 points
pts <- order(-runs_pp$n_runs)[1:6]
div <- bind_rows(lapply(c("prev", "gono_prev", "incid_rate"), function(v) {
  sel <- which(point %in% pts)
  tibble(var = v, year = rep(1:100, length(sel)),
    run = rep(sims[sel], each = 100), point = rep(point[sel], each = 100),
    value = as.vector(Y[[v]][1:100, sel]))
}))
p <- ggplot(div, aes(year, value, group = run, colour = factor(point))) +
  geom_line(linewidth = 0.25, alpha = 0.7) +
  facet_grid(var ~ ., scales = "free_y") +
  labs(x = "Years after the restart", y = NULL, colour = "restart point",
    title = "Runs restarted from the same state (6 most used points)",
    subtitle = "Each colour is one restart point; each line one run")
save_fig(p, "c4_01_same_point_runs.png", 11, 9)

save_session("c4_01")
