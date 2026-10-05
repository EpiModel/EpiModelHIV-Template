# =============================================================================
# c3_01_prepare.R
# Question : What is in the cold-start dataset? Was it produced with the same
#            parameters and model code as the x0 runs of cycles 1-2? What does
#            the cold-start state look like, and which annual dataset do the
#            later steps use?
# Inputs   : data/run/variance/df__variance_long_x0.rds (weekly, long format),
#            workflows/variance_assess_raw/SWF/steps/2/map.rds (netsim inputs),
#            data/input/model_parameters.csv, data/run/estimates/*-hpc.rds,
#            data/run/restart_assessment/01_annual.rds (cycle 1, read-only)
# Outputs  : cycle3/results/tables/c3_01_*.csv, figures/c3_01_*.png,
#            data/run/restart_assessment/cycle3/c3_01_annual_cold.rds
# Method   : c3_METHODS.md C3-M0, C3-M1; results/c3_01_prepare.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")
set.seed(SEED)

# Provenance of the runs (C3-M0) ------------------------------------------------
# (a) The exact `netsim` inputs that slurmworkflow shipped to the HPC.
wf <- readRDS(WF_MAP_PATH)$MoreArgs
init_fun_same <- identical(deparse(wf$control$initialize.FUN),
  deparse(EpiModelHIV::initialize_msm))
ini <- unlist(wf$init)
setup <- tibble(
  item = c("path_to_x", "nsteps", "start", "initialize.FUN is initialize_msm",
    "resimulate.network", "n_rep", "n_batch", "n_cores",
    paste0("init$", names(ini))),
  value = c(as.character(wf$path_to_x), wf$control$nsteps, wf$control$start,
    init_fun_same, wf$control$resimulate.network, wf$n_rep, wf$n_batch,
    wf$n_cores, as.character(ini))
)
write_tab(setup, "c3_01_run_setup.csv")
print(as.data.frame(setup))

# (b) Parameters: the list the cold-start runs used vs the list rebuilt from
# the current model_parameters.csv exactly as R/netsim_settings.R does. The
# x0 runs (2026-09-18) used that csv too (cycle 2, C2-M0); it has not changed
# since 2026-09-15 (see the file table below).
params_df <- read.csv(fs::path(input_dir, "model_parameters.csv")) |>
  select(param, value, type)
p_csv <- EpiModel::param.net(
  data.frame.params = params_df,
  netstats = readRDS(fs::path(est_dir, "netstats-hpc.rds")),
  epistats = readRDS(fs::path(est_dir, "epistats-hpc.rds")),
  prep.start = prep_start,
  riskh.start = prep_start - year_steps
)
p_wf <- wf$param
nm <- union(names(p_csv), names(p_wf))
pcmp <- tibble(
  param = nm,
  in_cold_runs = nm %in% names(p_wf),
  in_csv_build = nm %in% names(p_csv),
  identical = vapply(nm, function(n) identical(p_wf[[n]], p_csv[[n]]),
    logical(1))
)
write_tab(pcmp, "c3_01_param_compare.csv")
cat("Parameters compared:", nrow(pcmp), " identical:", sum(pcmp$identical),
  "\n")
rm(p_csv, p_wf, wf)

# (c) Model code: EpiModelHIV-p commit in renv.lock.hpc for each run, and the
# files of R/ that differ between the two commits (sibling clone).
lock_sha <- function(txt) {
  j <- jsonlite::fromJSON(paste(txt, collapse = "\n"), simplifyVector = FALSE)
  j$Packages$EpiModelHIV$RemoteSha
}
git <- function(...) {
  tryCatch(suppressWarnings(system2("git", c(...), stdout = TRUE,
    stderr = FALSE)), error = function(e) character(0))
}
sha_x0 <- lock_sha(git("show", paste0(RENV_UPDATE_COMMIT, "~1:renv.lock.hpc")))
sha_cold <- lock_sha(git("show", paste0(RENV_UPDATE_COMMIT, ":renv.lock.hpc")))
code_diff <- git("-C", EMHIV_REPO, "diff", "--numstat", sha_x0, sha_cold,
  "--", "R/")
if (!length(code_diff)) code_diff <- "git diff not available"
code <- tibble(
  item = c("EpiModelHIV-p commit, x0 runs (renv.lock.hpc before update)",
    "EpiModelHIV-p commit, cold-start runs", "installed locally",
    paste("R/ files that differ (added, deleted lines, file):", code_diff)),
  value = c(sha_x0, sha_cold, packageDescription("EpiModelHIV")$RemoteSha,
    rep("", length(code_diff)))
)
write_tab(code, "c3_01_code_versions.csv")
print(as.data.frame(code))

# (d) Network model: edges coefficients (C3-M0). A restarted run takes its
# formation coefficients from the restart file (`x$coef.form`), not from
# `netest`, and `EpiModel::edges_correct()` then only adds
# log(N_{t-1}) - log(N_t) each step. So the coefficient of any run satisfies
#   coef_t = c0 + offset + log(N_init / N_t),
# with c0 the netest coefficient and N_init = 100,000 nodes, and `offset` is
# a constant that no later step removes. It is computed here for the
# restart file of the x0 runs and for the September pool, which was built on
# the HPC from cold-start runs with the same code as the variance runs.
# (The cold-start variance runs themselves saved no coefficients, and the
# netest file they loaded is the HPC copy of `netest-hpc.rds`.)
net_local <- readRDS(fs::path(est_dir, "netest-hpc.rds"))
c0 <- vapply(net_local, function(x) unname(x$coef.form[1]), numeric(1))
n_init <- network::network.size(net_local[[1]]$newnetwork)
rm(net_local)
coef_offsets <- function(f, label) {
  r <- readRDS(fs::path(est_dir, f))
  # EpiModel restarts run s from x$run[[s]] and x$coef.form[[s]]; a file can
  # carry more coefficient sets than runs (restart-hpc.rds: 8 vs 1)
  cf <- t(vapply(r$coef.form[seq_along(r$run)], function(x) {
    vapply(x, function(y) unname(y[1]), numeric(1))
  }, numeric(length(c0))))
  n <- vapply(r$run, function(x) as.numeric(x$num), numeric(1))
  off <- sweep(cf, 2, c0) - log(n_init / n)
  bind_rows(lapply(seq_along(c0), function(k) {
    tibble(
      source = label, file = f, network = names(c0)[k],
      netest_coef_local = c0[k], n_points = nrow(cf),
      offset_min = min(off[, k]), offset_max = max(off[, k]),
      tie_propensity_ratio = exp(mean(off[, k])),
      num_elig_saved = !is.null(r$run[[1]]$num.elig)
    )
  }))
}
net_tab <- bind_rows(
  coef_offsets("restart-hpc.rds", "x0 of the variance runs (2026-05-20)"),
  coef_offsets("restart_pool.rds",
    "September pool (HPC cold starts, 2026-09-21)")
)
write_tab(net_tab, "c3_01_network_coefs.csv", 6)
print(as.data.frame(net_tab))

# (e) Input files and data files, with modification times
files <- c(fs::path(input_dir, "model_parameters.csv"),
  fs::path(est_dir, c("netest-hpc.rds", "netstats-hpc.rds",
    "epistats-hpc.rds")),
  DATA_PATH, COLD_PATH)
write_tab(tibble(file = as.character(files),
  modified = as.character(fs::file_info(files)$modification_time),
  md5 = unname(tools::md5sum(files))), "c3_01_files.csv")

# Load ------------------------------------------------------------------------
d <- readRDS(COLD_PATH)
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
  length(steps) == N_YEARS * year_steps, min(steps) == 1,
  all(table(d$sim) == length(steps))
)
raw_vars <- setdiff(names(d), c("sim", "time"))
kind <- ifelse(grepl("incid|^arrivals|^departures|^nNew$", raw_vars),
  "flow", "stock")

# Initialisation and first simulated week ----------------------------------------
# Step 1 is `initialize_msm()`: only `num` is recorded. Chains are not
# identical afterwards: the network at t = 1 and the attributes (infection
# times, STI status) are drawn at random in each run.
init_rows <- d[d$time == 1, raw_vars]
n_na <- vapply(d[raw_vars], function(x) sum(is.na(x)), numeric(1))
n_na_init <- vapply(init_rows, function(x) sum(is.na(x)), numeric(1))
wk1 <- d[d$time == 2, raw_vars]
first <- tibble(
  var = raw_vars, kind = kind,
  recorded_at_init = n_na_init == 0,
  init_identical = vapply(init_rows, function(x) {
    all(!is.na(x)) && length(unique(x)) == 1
  }, logical(1)),
  na_after_init = n_na - n_na_init,
  week1_distinct = vapply(wk1, function(x) length(unique(x)), numeric(1)),
  week1_mean = vapply(wk1, mean, numeric(1)),
  week1_sd = vapply(wk1, sd, numeric(1))
)
write_tab(first, "c3_01_first_steps.csv")
stopifnot(all(first$na_after_init == 0), all(init_rows$num == n_init))
cat("Recorded at initialisation:", first$var[first$recorded_at_init], "\n")

# Identities and duplicate chains -------------------------------------------------
# As in cycle 1: nNew = arrivals and totals = B + H + W (checked on 8 chains,
# recorded steps), and no two chains share a trajectory (checksums).
dd <- d[d$sim %in% sims[1:8] & d$time > 1, ]
race_sum <- vapply(raw_vars, function(tot) {
  parts <- paste0(tot, c(".B", ".H", ".W"))
  if (!all(parts %in% raw_vars)) return(NA)
  all(dd[[tot]] == dd[[parts[1]]] + dd[[parts[2]]] + dd[[parts[3]]])
}, logical(1))
w <- runif(length(steps) - 1)
checks <- tibble(
  check = c("nNew identical to arrivals",
    paste("total = B + H + W:", names(race_sum)[!is.na(race_sum)]),
    paste("distinct chains (checksum):", c("hiv.inf", "gono.inf", "num"))),
  result = c(identical(dd$nNew, dd$arrivals), race_sum[!is.na(race_sum)],
    vapply(c("hiv.inf", "gono.inf", "num"), function(v) {
      m <- matrix(as.double(d[[v]]), length(steps))[-1, ]
      length(unique(round(colSums(m * w), 6))) == n_sim
    }, logical(1)))
)
write_tab(checks, "c3_01_identities.csv")
rm(dd)

# Absorbing events: extinctions -------------------------------------------------
extinct <- d |>
  filter(time > 1) |>
  summarise(
    across(c(syph.inf, gono.inf, chla.inf, hiv.inf),
      ~ if (any(.x == 0)) (min(time[.x == 0]) - 1) / year_steps else NA_real_
    ),
    .by = sim
  ) |>
  filter(if_any(-sim, ~ !is.na(.x)))
write_tab(extinct, "c3_01_extinctions_year.csv")
print(extinct)
drop_sims <- extinct$sim

# Weekly cross-chain means of the first two years, for the figure
weekly <- d |>
  filter(time >= 2, time <= 2 * year_steps + 1) |>
  summarise(across(all_of(raw_vars), mean), .by = time)

# Annual aggregation (C3-M1) ----------------------------------------------------
# Year k covers steps (k - 1) * 52 + 1 ... k * 52. Step 1 has no record
# except num, so year 1 averages stocks over weeks 2-52 and rescales flow
# sums from 51 to 52 weeks.
annual_raw <- setNames(lapply(seq_along(raw_vars), function(i) {
  annualise(d[[raw_vars[i]]], kind[i], N_YEARS, n_sim)
}), raw_vars)
rm(d, init_rows, wk1)
gc()

# Derived variables ----------------------------------------------------------------
# Check first that derive_vars() reproduces cycle 1 from its own raw values.
a1 <- readRDS(X0_ANNUAL_PATH)
chk <- derive_vars(a1$Y)
err <- vapply(names(chk), function(v) max(abs(chk[[v]] - a1$Y[[v]])),
  numeric(1))
cat("Max |derive_vars - cycle 1|:", max(err), "\n")
stopifnot(max(err) < 1e-12)
dict1 <- a1$dict
pi_x0 <- vapply(dict1$name[dict1$block == "key"], function(v) {
  mean(a1$Y[[v]][LATE_START:N_YEARS, ])
}, numeric(1))
rm(a1, chk)

Y <- add_project_vars_c3(c(derive_vars(annual_raw), annual_raw))

# Dictionary: cycle 1 blocks unchanged (key, state, other); the new weekly
# counts in `other`; the project variables of cycles 2-3 in `project`.
rules <- project_rules()
proj_vars <- names(rules)[names(rules) %in% names(Y)]
new_raw <- setdiff(raw_vars, dict1$name)
dict <- bind_rows(
  dict1 |> mutate(notes = ifelse(grepl("dropped", notes), "", notes)),
  tibble(name = new_raw, kind = kind[match(new_raw, raw_vars)],
    annual_aggregation = "sum", block = "other", analysis_scale = "raw",
    notes = "new output (EpiModelHIV-p 6e6bff15)"),
  tibble(name = proj_vars,
    kind = ifelse(grepl("^cml|^ir100|mr100", proj_vars), "rate or sum",
      "proportion (stock / stock)"),
    annual_aggregation = unname(rules[proj_vars]), block = "project",
    analysis_scale = "raw", notes = "project variable (C2-M1, C3-M1)")
)
write_tab(dict, "c3_01_variable_dictionary.csv")

# Assemble, dropping chains with an absorbing extinction ----------------------------
keep <- !(sims %in% drop_sims)
annual <- list(
  Y = lapply(Y[dict$name], function(y) y[, keep, drop = FALSE]),
  sims = sims[keep],
  dropped = drop_sims,
  years = seq_len(N_YEARS),
  dict = dict,
  weekly_first2y = weekly
)
saveRDS(annual, COLD_ANNUAL_PATH)
cat("Chains kept:", sum(keep), " annual object size:",
  format(object.size(annual), units = "MB"), "\n")

# The cold-start state against pi ------------------------------------------------
# Year-1 annual values and the first simulated week (stocks only) against
# the stationary law of the same runs (years >= LATE_START) and of the x0
# runs (cycle 1). z = (value - mu_pi) / SD_pi.
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
wk_list <- lapply(weekly[1, raw_vars], as.matrix)
wk_derived <- add_project_vars_c3(c(derive_vars(wk_list), wk_list))
init_state <- bind_rows(lapply(c(key, state, proj_vars), function(v) {
  y <- annual$Y[[v]]
  pm <- pi_moments(y, LATE_START:N_YEARS)
  w1 <- if (v %in% names(wk_derived)) wk_derived[[v]][1] else
    if (v %in% raw_vars) weekly[[v]][1] else NA_real_
  flow_like <- v %in% raw_vars[kind == "flow"] ||
    grepl("incid_rate|_ir$|^ir100|mr100|cml", v)
  tibble(
    var = v, block = dict$block[match(v, dict$name)],
    week1_mean = if (flow_like) NA_real_ else w1,
    year1_mean = mean(y[1, ]), year1_sd = sd(y[1, ]),
    pi_mean = pm$mu, pi_sd = sqrt(pm$s2),
    z_week1 = (week1_mean - pm$mu) / sqrt(pm$s2),
    z_year1 = (year1_mean - pm$mu) / sqrt(pm$s2),
    sd_ratio_year1 = year1_sd / sqrt(pm$s2),
    pi_mean_x0_runs = unname(pi_x0[v])
  )
}))
write_tab(init_state, "c3_01_initial_state.csv")
print(as.data.frame(filter(init_state, block == "key")))

# Sanity figures ----------------------------------------------------------------------
Yk <- annual$Y
show <- sample(ncol(Yk[[1]]), 10)
band <- bind_rows(lapply(key, function(v) {
  tibble(var = v, year = annual$years, mean = rowMeans(Yk[[v]]),
    q05 = apply(Yk[[v]], 1, quantile, 0.05),
    q95 = apply(Yk[[v]], 1, quantile, 0.95))
}))
chains <- bind_rows(lapply(key, function(v) {
  tibble(var = v, year = rep(annual$years, 10),
    chain = rep(show, each = N_YEARS), value = as.vector(Yk[[v]][, show]))
}))
ref_x0 <- tibble(var = key, value = pi_x0[key])
p <- ggplot(band, aes(year)) +
  geom_line(data = chains, aes(y = value, group = chain), alpha = 0.25,
    linewidth = 0.2) +
  geom_ribbon(aes(ymin = q05, ymax = q95), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = mean), colour = "steelblue4") +
  geom_hline(data = ref_x0, aes(yintercept = value), colour = "red",
    linetype = 2) +
  facet_wrap(~var, scales = "free_y", ncol = 4) +
  labs(x = "Years after the cold start", y = NULL,
    title = "Key variables after a cold start: 10 chains, mean and 5-95% band",
    subtitle = "Red dashed: stationary mean of the x0 runs (cycle 1, years >= 300)")
save_fig(p, "c3_01_key_600y.png", 14, 16)
save_fig(p + coord_cartesian(xlim = c(0, 150)), "c3_01_key_first150y.png",
  14, 16)

wk_show <- c("hiv.inf", "hiv.dx", "hiv.tx", "hiv.supp", "hiv.incid",
  "hiv.dx.incid", "prep", "prep.indic", "gono.inf", "chla.inf", "syph.inf",
  "num")
pi_raw <- vapply(wk_show, function(v) {
  mean(annual$Y[[v]][LATE_START:N_YEARS, ]) /
    if (kind[match(v, raw_vars)] == "flow") year_steps else 1
}, numeric(1))
write_tab(tibble(var = wk_show, week1_mean = unlist(weekly[1, wk_show]),
  pi_weekly_mean = pi_raw, ratio = week1_mean / pi_weekly_mean),
  "c3_01_week1_vs_pi.csv")
p <- weekly |>
  select(time, all_of(wk_show)) |>
  tidyr::pivot_longer(-time) |>
  mutate(value = value / pi_raw[name]) |>
  ggplot(aes((time - 1) / year_steps, value)) +
  geom_hline(yintercept = 1, linetype = 2) +
  geom_line() +
  facet_wrap(~name, scales = "free_y") +
  labs(x = "Years after the cold start (weekly)",
    y = "Cross-chain mean / stationary mean",
    title = "First two years after the cold start, weekly cross-chain means",
    subtitle = "Flows are compared with the stationary weekly mean")
save_fig(p, "c3_01_first2y_weekly.png", 12, 8)

save_session("c3_01")
