library("EpiModelHIV")
library("dplyr")
library("tidyr")
library("ggplot2")
library("future.apply")

# Settings ---------------------------------------------------------------------
context <- if (!exists("context")) "local" else context
if (context == "local") {
  plan(sequential)
} else if (context == "hpc") {
  plan(multisession, workers = ncores)
} else  {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

source("R/utils-0_project_settings.R")

source("./R/utils-targets.R")
batches_infos <- EpiModelHPC::get_scenarios_batches_infos(calib_dir)

process_one_plot_calib_batch <- function(scenario_infos, modulo_steps) {
  d_sim <- readRDS(scenario_infos$file_name) %>%
    as_tibble() %>%
    mutate_calibration_targets()

  plot_dirs <- c()

  for (plot_name in names(targets_plot_infos)) {
    plot_infos <- targets_plot_infos[[plot_name]]
    if (!all(plot_infos$names %in% names(d_sim))) next

    d_outcomes <- d_sim %>%
      select(sim, time, all_of(plot_infos$names)) %>%
      group_by(sim) %>%
      arrange(time) %>%
      mutate(across(
        all_of(plot_infos$names),
        ~ RcppRoll::roll_meanl(.x, n = plot_infos$window_size, by = 1)
      )) %>%
      ungroup() %>%
      select(-sim) %>%
      pivot_longer(- time, names_to = "name", values_to = "value") %>%
      filter(time == 1 | time %% modulo_steps == 0)

      plot_dir <- fs::path(fs::path_dir(scenario_infos$file_name), plot_name)
      if (!fs::dir_exists(plot_dir)) fs::dir_create(plot_dir)

      batch_name <- fs::path_file(scenario_infos$file_name)
      saveRDS(d_outcomes, fs::path(plot_dir, batch_name))

      plot_dirs <- c(plot_dirs, plot_dir)
  }

  plot_dirs
}

make_this_target_plot <- function(plot_dir) {
  plot_name <- fs::path_file(plot_dir)
  plot_infos <- targets_plot_infos[[plot_name]]

  d_sim <- lapply(fs::dir_ls(plot_dir), readRDS) %>%
    bind_rows()

  d_outcomes <- d_sim %>%
    group_by(name, time) %>%
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
