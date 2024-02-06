# can I simply use the manual_1_process.R

# To be run after merge_netsim_tibble

# for each merged_tibble
#   make calibration targets
#   calc q1, q2, q3
#   combine calib_vals
#
#   make calibration dist
#   calc q1, q2, q3
#   combine calib_dists
source("./R/shared_variables.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
calib_steps <- year_steps
d_calibs <- fs::path(calib_dir, "merged_tibbles", "df__empty_scenario.rds")

d_dist <- readRDS(d_calibs) |>
  dplyr::filter(time >= max(time) - calib_steps) |>
  EpiModelHIV::mutate_calibration_distances() |>
  dplyr::select(batch_number, sim, dplyr::any_of(names(targets)))

d_dist <- d_dist |>
  dplyr::group_by(batch_number, sim) |>
  dplyr::summarize(
    dplyr::across(dplyr::everything(), mean),
    .groups = "drop"
  )

d_dist$cost <- 0

# calc squared error
for (nme in names(targets)) {
  if (nme %in% names(d_dist)) {
    d_dist$cost <- d_dist$cost + d_dist[[nme]]^2
  }
}

# pick best sim
best_sim <- d_dist |>
  dplyr::arrange(cost) |>
  dplyr::select(batch_number, sim) |>
  head(1)

# Check the values manually
d_dist |>
  dplyr::arrange(cost) |>
  head(1) |>
  as.list()

# Get best sim
best <- readRDS(fs::path(
  calib_dir,
  paste0("sim__empty_scenario__", best_sim$batch_number, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)

# Remove all epi except `num`
best$epi <- list(
  num = best$epi$num,
  sim.num = best$epi$sim.num
)

saveRDS(best, path_to_restart)

# make calibraion plots
targets_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.linked1m = list(
    names = paste0("cc.linked1m.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.vsupp = list(
    names = paste0("cc.vsupp.", c("B", "H", "W")),
    window_size = 13
  ),
  i.prev.dx = list(
    names = paste0("i.prev.dx.", c("B", "H", "W")),
    window_size = 13
  ),
  ir100.sti = list(
    names = c("ir100.gc", "ir100.ct"),
    window_size = 52
  ),
  cc.prep.ind = list(
    names = paste0("cc.prep.ind.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.prep = list(
    names = paste0("cc.prep.", c("B", "H", "W")),
    window_size = 13
  ),
  disease.mr100 = list(
    names = "disease.mr100",
    window_size = 13
  )
)

d_tar <- readRDS(d_calibs) |>
  EpiModelHIV::mutate_calibration_targets(year_steps) |>
  dplyr::select(batch_number, sim, time, dplyr::any_of(names(targets)))

plot_dirs <- c()

plot_name <- names(targets_plot_infos)[[1]]
modulo_steps <- 2

library(dplyr)
library(tidyr)

for (plot_name in names(targets_plot_infos)) {
  plot_infos <- targets_plot_infos[[plot_name]]
  if (!all(plot_infos$names %in% names(d_tar))) next

  d_outcomes <- d_tar |>
    select(batch_number, sim, time, all_of(plot_infos$names)) |>
    group_by(batch_number, sim) |>
    arrange(time) |>
    mutate(across(
      all_of(plot_infos$names),
      ~ RcppRoll::roll_meanl(.x, n = plot_infos$window_size, by = 1)
    )) |>
    ungroup() |>
    select(-c(batch_number, sim)) |>
    pivot_longer(- time, names_to = "name", values_to = "value") |>
    filter(time == 1 | time %% modulo_steps == 0) |>
    group_by(name, time) |>
    summarise(
      q1 = quantile(value, 0.25, na.rm = TRUE),
      q2 = quantile(value, 0.50, na.rm = TRUE),
      q3 = quantile(value, 0.75, na.rm = TRUE)
    )

    d_tar <- tibble(
      name = plot_infos$names,
      value = targets[name]
    )

    plot_this_target(d_outcomes, d_tar)
}

plot_this_target <- function(d_outcomes, d_tar) {
  theme_set(theme_classic())
  p <- ggplot(
    d_outcomes,
    aes(x = time, y = q2, ymin = q1, ymax = q3, col = name, fill = name)
  ) +
    geom_line() +
    geom_ribbon(alpha = 0.6, linetype = 0) +
    geom_hline(
      data = d_tar,
      aes(yintercept = value, col = name),
      linetype = 2
    ) +
    xlab("Calibration Weeks") +
    ylab("Value") +
    theme(legend.title = element_blank())
  p
}

plot_dirs <- future_lapply(
  seq_len(nrow(batches_infos)),
  function(i) process_one_plot_calib_batch(batches_infos[i, ], 4),
  future.seed = TRUE
)

plot_dirs <- plot_dirs[[1]]

plots <- future_lapply(plot_dirs, make_this_target_plot, future.seed = TRUE)
names(plots) <- fs::path_file(plot_dirs)
saveRDS(plots, fs::path(calib_dir, "calibration_plots", ext = "rds"))
