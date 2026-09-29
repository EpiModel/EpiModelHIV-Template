## Make the new restart pool from the `new_pool` workflows
##
## Reads the runs of `workflow-new_pool.R`: the main batch (32 runs,
## `data/run/new_pool/`) and the replacement batch (8 runs,
## `data/run/new_pool_extra/`), all 150 years under the current parameters.
## It:
##   1. applies the STI filter: every STI ir100 >= 50% of its target, on the
##      mean of the last 10 years (a single year is too noisy: the yearly SD
##      of ir100.syph within a run is 0.45);
##   2. keeps the main runs that pass, then the first replacement runs that
##      pass, until there are 32;
##   3. checks equilibrium (years 101-125 vs 126-150) and the targets
##      (years 141-150) on those 32;
##   4. builds the pool from their final states, checks its network
##      coefficients (C3-M0) and parameters;
##   5. saves it as `data/run/estimates/restart_pool_new.rds`. It does NOT
##      replace `restart_pool.rds`: that is done by hand after review.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
hpc_context <- TRUE

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/C-new_calibration/z-context.R", local = TRUE)
source("R/C-new_calibration/utils-restart_pool_tools.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)

n_pool    <- 32
sources   <- c(main = "new_pool", extra = "new_pool_extra")
check_dir <- fs::path(run_dir, "new_pool", "checks")
fs::dir_create(check_dir)
targets <- EpiModelHIV::get_calibration_targets()
targets <- targets[names(targets) != "cc.prep"]

# Annual target values of every run, both batches ------------------------------------
ann <- bind_rows(lapply(names(sources), function(s) {
  readRDS(fs::path(run_dir, sources[[s]], "merged_tibbles", "df__empty_scenario.rds")) |>
    mutate_calibration_targets() |>
    mutate(year = (time - restart_time) %/% year_steps + 1, prev = hiv.inf / num) |>
    filter(year <= 150) |>
    summarise(across(c(prev, num, any_of(names(targets))), \(x) mean(x, na.rm = TRUE)),
      .by = c(sim, year)) |>
    mutate(source = s)
}))

# 1. STI filter on the last 10 years ------------------------------------------------------
last10 <- ann |> filter(year > 140) |>
  summarise(across(c(ir100.gono, ir100.chla, ir100.syph), mean), .by = c(source, sim)) |>
  mutate(sti_ok = ir100.gono >= 0.5 * targets[["ir100.gono"]] &
    ir100.chla >= 0.5 * targets[["ir100.chla"]] &
    ir100.syph >= 0.5 * targets[["ir100.syph"]])
write.csv(last10, fs::path(check_dir, "sti_filter.csv"), row.names = FALSE)
print(last10 |> filter(!sti_ok))

# 2. The 32 states: passing main runs, then passing replacement runs in order ------
chosen <- bind_rows(
  last10 |> filter(source == "main", sti_ok) |> arrange(sim),
  last10 |> filter(source == "extra", sti_ok) |> arrange(sim)
) |> slice_head(n = n_pool) |> select(source, sim)
cat("Pool:", sum(chosen$source == "main"), "main runs +", sum(chosen$source == "extra"),
  "replacement runs\n")
stopifnot(nrow(chosen) == n_pool)
write.csv(chosen, fs::path(check_dir, "chosen_runs.csv"), row.names = FALSE)
ann <- semi_join(ann, chosen, by = c("source", "sim"))
ann$run <- paste(ann$source, ann$sim)

# 3a. Equilibrium: years 101-125 against 126-150, per run ------------------------
vars <- c("prev", "num", names(targets))
eq <- bind_rows(lapply(vars, function(v) {
  a <- ann |> filter(year %in% 101:125) |> summarise(m = mean(.data[[v]]), .by = run)
  b <- ann |> filter(year %in% 126:150) |> summarise(m = mean(.data[[v]]), .by = run)
  dd <- b$m - a$m[match(b$run, a$run)]
  sd_run <- sd(ann[[v]][ann$year %in% 126:150])
  tibble(var = v, mean_101_125 = mean(a$m), mean_126_150 = mean(b$m),
    change_sd = mean(dd) / sd_run, z = mean(dd) / (sd(dd) / sqrt(length(dd))))
}))
write.csv(eq, fs::path(check_dir, "equilibrium.csv"), row.names = FALSE)
print(as.data.frame(eq), digits = 3)

# 3b. Targets at the end ----------------------------------------------------------------
end <- ann |> filter(year %in% 141:150) |>
  summarise(across(all_of(names(targets)), mean)) |> unlist()
tab <- tibble(target = names(targets), value = unname(targets),
  new_pool_141_150 = end[names(targets)],
  rel_error = end[names(targets)] / targets - 1)
write.csv(tab, fs::path(check_dir, "targets.csv"), row.names = FALSE)
print(as.data.frame(tab), digits = 3)
cat("Mean |relative error| over", nrow(tab), "targets:",
  round(mean(abs(tab$rel_error)), 3), "\n")

# 4. Build the pool from the final states ---------------------------------------------
attrs_names <- names(EpiModelHIV::get_default_attrs())
time_attrs <- grep("\\.last$|\\.time$", attrs_names, value = TRUE)
parts <- lapply(names(sources), function(s) {
  sims <- chosen$sim[chosen$source == s]
  if (!length(sims)) return(NULL)
  raw <- readRDS(fs::path(run_dir, sources[[s]], "sim__empty_scenario__1.rds"))
  x <- make_restart_point(raw, time_attrs, sims_num = sims)
  rm(raw)
  gc()
  x
})
pool <- Reduce(merge_restart_points, Filter(Negate(is.null), parts))
rm(parts)
stopifnot(length(pool$run) == n_pool, length(pool$coef.form) == n_pool)

# 5. Checks: network offsets (C3-M0) and parameters -------------------------------
net <- readRDS(path_to_est)
c0 <- vapply(net, function(x) unname(x$coef.form[1]), numeric(1))
n_init <- network::network.size(net[[1]]$newnetwork)
rm(net)
cf <- t(vapply(pool$coef.form, function(x) {
  vapply(x, function(y) unname(y[1]), numeric(1))
}, numeric(length(c0))))
n_pt <- vapply(pool$run, function(x) as.numeric(x$num), numeric(1))
off <- sweep(cf, 2, c0) - log(n_init / n_pt)
off_tab <- tibble(network = names(c0), offset_min = apply(off, 2, min),
  offset_max = apply(off, 2, max))
write.csv(off_tab, fs::path(check_dir, "network_offsets.csv"), row.names = FALSE)
print(off_tab)
stopifnot(max(abs(off)) < 1e-8)

common <- intersect(names(pool$param), names(param))
same <- vapply(common, function(n) isTRUE(all.equal(pool$param[[n]], param[[n]])),
  logical(1))
cat("Parameters equal to model_parameters.csv:", sum(same), "of", length(common), "\n")
stopifnot(all(same))
cat("Filled from the pool if missing from param:",
  paste(setdiff(names(pool$param), names(param)), collapse = ", "), "\n")

# 6. Save (without replacing the current pool) -------------------------------------
saveRDS(pool, fs::path(est_dir, "restart_pool_new.rds"))
cat("Saved", fs::path(est_dir, "restart_pool_new.rds"), "with", length(pool$run),
  "points\n")
