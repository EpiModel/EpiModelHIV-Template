# Setup ------------------------------------------------------------------------
# variables required:
#   - scenario_name
#   - pool_dir
#   - sims_dir
#   - max_n

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/Z-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

path_df <- fs::path(
  sims_dir,
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

# calculate Squared Error
for (nme in names(targets)) {
  d_dist$cost <- d_dist$cost + d_dist[[nme]]^2
}

# Ensure every STI ir100 is at least 50% of the targets.
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
best_sim <- d_dist |>
  filter(!is.infinite(cost)) |>
  slice_head(n = max_n)

attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")

time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

EpiModelHPC::make_restart_pool(
  pool_dir = pool_dir,
  scenario_name = scenario_name,
  scenarios_dir = sims_dir,
  keep_sims = best_sim,
  time_attrs = time_attrs
)

syph_res <- best_sim |>
  select(batch_number, sim_number, ir100.syph) |>
  mutate(ir100.syph = ir100.syph + targets["ir100.syph"])
pool_index <- read.csv(fs::path(pool_dir, "pool_index.csv")) |>
  left_join(syph_res, by = c("batch_number", "sim_number"))

write.csv(
  pool_index,
  fs::path(pool_dir, "pool_index.csv"),
  row.names = FALSE
)
