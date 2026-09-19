## Choose Restart Point
##
##  Assess the candidates simulations for restart point, pick the best one and
##  save it in `path_to_restart`.
##
## This script should not be run directly. But `sourced` from the restart_point
## workflow

# Setup ------------------------------------------------------------------------
scenario_name <- "empty_scenario"
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

# Relation between syph prev and syph ir100
d_calibs |>
  mutate(syph.prev = syph.inf / num) |>
  select(batch_number, sim_number, syph.prev, ir100.syph) |>
  summarize(
    across(everything(), mean),
    .by = c("batch_number", "sim_number")
  ) |>
  ggplot( aes(y = syph.prev, x = ir100.syph)) +
  geom_point() +
  geom_smooth()


# calculate Squared Error
for (nme in names(targets)) {
  d_dist$cost <- d_dist$cost + d_dist[[nme]]^2
}

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

if (all(d_dist$cost == Inf))
  stop("No simulation has all the STI epidemics ongoing. Aborting")

# pick best sim
d_dist |>
  filter(cost < Inf) |>
  arrange(cost) |>
  select(starts_with("ir100")) |>
  print(n = 100)

# pick best sim
best_sims <- d_dist |>
  filter(cost < Inf)

batch_numbers <- unique(best_sims$batch_number)

# Make the restart pool --------------------------------------------------------
attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")
time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

restart_pools <- vector(mode = "list", length = length(batch_numbers))

for (batch in batch_numbers) {
  sims_num <- filter(best_sims, batch_number == batch) |>
    pull(sim_number) |>
    unique()
  restart_pools[[batch]] <- make_restart_point(
    readRDS(paste0("./data/run/calibration/sim__bad_calib__", batch, ".rds")),
    time_attrs,
    sims_num = sims_num
  )
}

restart_pools <- Reduce(merge_restart_points, restart_pools)
saveRDS(restart_pools, "./data/run/estimates/restart_pool.rds")
