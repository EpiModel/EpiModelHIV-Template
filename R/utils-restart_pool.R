add_to_restart_pool <- function(sims, pool_dir) {
  if (!dir.exists(pool_dir)) {
    message("Creating a new restart pool at: \n\"", pool_dir, "\"")
    dir.create(pool_dir)
    pool_last <- 0
  } else {
    pool <- list.files(pool_dir, "^\\d+\\.rds$")
    pool_nums <- as.numeric(sub("\\.rds", "", pool))
    pool_last <- max(pool_nums)
  }
  for (i in seq_along(sims)) {
    saveRDS(sims[[i]], paste0(pool_dir, "/", pool_last + i, ".rds"))
  }
}

make_restart_pool <- function(
  pool_dir,
  scenarios_dir,
  scenario_name,
  keep_sims,
  time_attrs
) {
  if (dir.exists(pool_dir))
    stop("A restart pool at this location already exists")
  b_infos <- EpiModelHPC::get_scenarios_batches_infos(scenarios_dir)
  b_infos <- b_infos[b_infos$scenario_name == scenario_name, , drop = FALSE]
  for (batch in unique(keep_sims$batch_number)) {
    batch_path <- b_infos$file_path[b_infos$batch_number == batch]
    sims <- lapply(
      sort(unique(keep_sims$sim_number[keep_sims$batch_number == batch])),
      make_restart_point,
      sim_obj = readRDS(batch_path),
      time_attrs = time_attrs
    )
    add_to_restart_pool(sims, pool_dir)
  }
}

netsim_path_wrapper_multi <- function(x_path, param, init, control, sim_nums) {
  control$nsims <- 1
  control$ncores <- 1
  control$future.use.plan <- FALSE

  if (dir.exists(x_path)) {
    # case: point to a dir of start objects
    size <- length(list.files(pool_dir, "^\\d+\\.rds$"))
    start_nums <- (sim_nums - 1) %% size + 1
    orig_paths <- paste0(x_path, "/", start_nums, ".rds")
    if (!all(file.exists(orig_paths))) {
      stop("Error in the restart paths. Check the directory.")
    }
  } else if (file.exists(x_path)) {
    # case: it's a file
    orig_paths <- rep(x_path, length(sim_nums))
  } else {
    stop("`x_path` points to neither of file or directory.")
  }
  sim_list <- future.apply::future_lapply(
    orig_paths,
    function(orig_path) {
      netsim(readRDS(orig_path), param, init, control)
    },
    future.seed = TRUE
  )
  sim_list
}

## Choose Restart Point
##
##  Assess the candidates simulations for restart point, pick the best one and
##  save it in `path_to_restart`.
##
## This script should not be run directly. But `sourced` from the restart_point
## workflow

# Setup ------------------------------------------------------------------------
scenario_name <- "default"
hpc_context <- TRUE

library(EpiModelHIV)
library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-new_calibration/z-context.R", local = TRUE)
source("./R/C-new_calibration/utils-restart_pool_tools.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

path_df <- fs::path(
  calib_dir,
  "merged_tibbles",
  paste0("df__", scenario_name, ".rds")
)

d_calibs <- readRDS(path_df) |>
  filter(time >= max(time) - year_steps) |>
  mutate(
    hiv.dx.incid.B = NA,
    hiv.dx.incid.H = NA,
    hiv.dx.incid.W = NA
  ) |>
  EpiModelHIV::mutate_calibration_targets()
targets <- targets[intersect(names(targets), names(d_calibs))]

d_dist <- d_calibs |>
  select(batch_number, sim_number, any_of(names(targets))) |>
  mutate(across(names(targets), \(x) x - targets[cur_column()])) |>
  summarize(
    across(everything(), mean),
    .by = c("batch_number", "sim_number")
  ) |>
  mutate(cost = 0)

# Ensure every STI ir100 is at least 75% of the targets.
# (d_dist contains distances from targets)
for (sti in names(has_sti)) {
  if (has_sti[sti]) {
    sti_tar <- paste0("ir100.", sti)
    d_dist$cost <- ifelse(
      d_dist[[sti_tar]] < -0.5 * targets[[sti_tar]],
      Inf,
      d_dist$cost
    )
  }
}

if (all(d_dist$cost == Inf)) {
  stop("No simulation has all the STI epidemics ongoing. Aborting")
}

# pick best sim
best_sims <- d_dist |>
  filter(cost < Inf) |>
  select(batch_number, sim_number)


# Make the restart pool --------------------------------------------------------
attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")
time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

# TODO: continue from here - do some tests
make_restart_pool(
  pool_dir = "./data/run/estimates/pool_test",
  scenarios_dir = "./data/run/calibration/",
  scenario_name = scenario_name,
  keep_sims = best_sims,
  time_attrs = time_attrs
)
