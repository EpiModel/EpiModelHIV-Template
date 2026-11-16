## Make a Restart Pool
##
## Turns the simulations of a pool run (`workflow-restart_point.R` writes them
## to `calib_dir`) into a restart pool at `pool_dir`: one restart point per
## simulation whose bacterial STI epidemics are all alive, up to `max_n`. The
## simulations are not selected on their distance to the targets; the pool is
## meant to carry the run-to-run variance (Adrien's restart pool design for the
## Gaussian process calibration).
##
## The pool has the layout of EpiModelHPC's restart pools (EpiModelHPC 2.10.0),
## and is checked with its `validate_restart_pool()`:
## `1.rds`, `2.rds`, ... and a `pool_index.csv` with `pool_num`,
## `scenario_name`, `batch_number`, `sim_number`, `file_path` and
## `epimodel_version`, plus the cost and STI rates of each member. It is
## written in a hidden `.<name>.partial` directory, renamed once complete. The
## elements are made with `make_restart_point_hiv()`, which shifts the `.due`
## attributes as well as `.last` and `.time`.
##
## Runs as a step of `workflow-restart_pool.R` (and of `workflow-pass_probe.R`,
## which also passes `calib_pass`), which passes:
##   - `scenario_name`: the scenario of the simulation files
##   - `sims_dir`: the directory holding them and their `merged_tibbles/`
##   - `pool_dir`: the pool to create; it must not exist
##   - `max_n`: the largest pool size
##   - `min_sti_frac`: each STI's target rate, as a fraction of its target,
##     below which a simulation is left out. The STI targets are found in the
##     target set (`sti_target_names()` in `R/calibration_targets.R`).

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)
hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/C-calibration/utils-restart.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- project_calibration_targets()

if (fs::dir_exists(pool_dir)) {
  stop("A restart pool already exists at: ", pool_dir)
}

path_df <- fs::path(
  sims_dir,
  "merged_tibbles",
  paste0("df__", scenario_name, ".rds")
)

d_calibs <- readRDS(path_df) |>
  filter(time >= max(time) - year_steps) |>
  EpiModelHIV::mutate_calibration_targets()
targets <- targets[intersect(names(targets), names(d_calibs))]

sti_true <- c(gono = "ir100.gono", chla = "ir100.chla", syph = "ir100.syph")
d_sims <- d_calibs |>
  select(batch_number, sim_number, any_of(names(targets)),
         any_of(unname(sti_true))) |>
  summarize(
    across(everything(), mean),
    .by = c("batch_number", "sim_number")
  )

# Squared error, recorded in the index but not used to select
d_sims$cost <- 0
for (nme in names(targets)) {
  d_sims$cost <- d_sims$cost + (d_sims[[nme]] - targets[[nme]])^2
}

sti_targets <- sti_target_names(project_calibration_targets())
sti_targets <- sti_targets[intersect(names(sti_targets),
                                     names(has_sti)[has_sti])]
sti_alive <- rep(TRUE, nrow(d_sims))
if (all(sti_targets %in% names(d_sims))) {
  for (sti_tar in sti_targets) {
    sti_alive <- sti_alive &
      d_sims[[sti_tar]] >= min_sti_frac * targets[[sti_tar]]
  }
  message(
    sum(sti_alive), " of ", nrow(d_sims), " simulations have every STI ",
    "target rate (", paste(sti_targets, collapse = ", "), ") at ",
    min_sti_frac, " of its target or more"
  )
} else {
  # Simulations that do not carry a target's series (made by an engine that
  # does not compute it) are kept if every STI is alive in the final year.
  for (sti_inc in sti_true[names(has_sti)[has_sti]]) {
    sti_alive <- sti_alive & d_sims[[sti_inc]] > 0
  }
  message(
    sum(sti_alive), " of ", nrow(d_sims), " simulations have every STI ",
    "alive in the final year (no ",
    paste(setdiff(sti_targets, names(d_sims)), collapse = ", "),
    " in these simulations)"
  )
}
if (!any(sti_alive)) {
  stop("No simulation has all the STI epidemics ongoing. Aborting")
}

keep_sims <- d_sims[sti_alive, ] |>
  arrange(batch_number, sim_number) |>
  slice_head(n = max_n)

# Write the pool -------------------------------------------------------------
partial_dir <- fs::path(
  fs::path_dir(pool_dir),
  paste0(".", fs::path_file(pool_dir), ".partial")
)
if (fs::dir_exists(partial_dir)) fs::dir_delete(partial_dir)
fs::dir_create(partial_dir)

keep_sims$pool_num <- seq_len(nrow(keep_sims))
keep_sims$scenario_name <- scenario_name
keep_sims$file_path <- NA_character_
keep_sims$epimodel_version <- NA_character_
for (batch in unique(keep_sims$batch_number)) {
  sim_path <- fs::path(
    sims_dir,
    paste0("sim__", scenario_name, "__", batch, ".rds")
  )
  if (!fs::file_exists(sim_path)) {
    stop("`sim` file: '", sim_path, "' not present.")
  }
  sim <- readRDS(sim_path)
  for (i in which(keep_sims$batch_number == batch)) {
    restart_point <- make_restart_point_hiv(
      sim = sim,
      sim_num = keep_sims$sim_number[i],
      sim_cost = keep_sims$cost[i]
    )
    version <- attr(restart_point, "version")
    keep_sims$epimodel_version[i] <-
      if (is.null(version)) NA_character_ else as.character(version)
    keep_sims$file_path[i] <- sim_path
    saveRDS(restart_point, fs::path(partial_dir, paste0(i, ".rds")))
  }
  rm(sim)
}

if (anyNA(keep_sims$epimodel_version)) {
  stop(
    "Some restart points carry no EpiModel version: the simulations come ",
    "from an EpiModel older than 2.7.0, which `netsim` cannot restart from"
  )
}

pool_index <- keep_sims |>
  select(
    pool_num, scenario_name, batch_number, sim_number, file_path,
    epimodel_version, cost, any_of(unname(sti_targets)),
    any_of(unname(sti_true))
  )
write.csv(
  pool_index,
  fs::path(partial_dir, "pool_index.csv"),
  row.names = FALSE
)
fs::file_move(partial_dir, pool_dir)
# The checks EpiModelHPC makes before running scenarios from a pool
EpiModelHPC::validate_restart_pool(pool_dir)
message("Restart pool of ", nrow(pool_index), " members at ", pool_dir)
