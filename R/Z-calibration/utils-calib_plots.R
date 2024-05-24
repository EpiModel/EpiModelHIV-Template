library(tidyr)
library(dplyr)
library(ggplot2)

# Common plot function for calibration
#   line plot with IQR
plot_this_target <- function(d_outcomes, d_tar) {
  theme_set(theme_classic())
  ggplot(
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
    xlab("Time steps") +
    ylab("Value") +
    theme(legend.title = element_blank())
}


make_calib_plots <- function(d_path, out_dir, calib_plot_infos, year_steps) {
  modulo_steps <- 2
  plot_data_dir <- fs::path(out_dir, "data")
  if (!fs::dir_exists(plot_data_dir)) fs::dir_create(plot_data_dir)
  targets <- EpiModelHIV::get_calibration_targets()

  d_calibs <- readRDS(d_path) |>
    EpiModelHIV::mutate_calibration_targets(year_steps) |>
    dplyr::select(batch_number, sim, time, dplyr::any_of(names(targets)))

  for (plot_name in names(calib_plot_infos)) {
    plot_infos <- calib_plot_infos[[plot_name]]
    if (!all(plot_infos$names %in% names(d_calibs))) next

    d_outcomes <- d_calibs |>
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

      p <- plot_this_target(d_outcomes, d_tar)
      saveRDS(p, fs::path(plot_data_dir, paste0(plot_name, ".rds")))
  }
}

generate_calib_plots <- function(out_dir) {
  plots <- fs::dir_ls(fs::path(out_dir, "data"))
  plots_dir <- fs::path(out_dir, "plots")
  if (!fs::dir_exists(plots_dir)) fs::dir_create(plots_dir)

  for (i in seq_along(plots)) {
    plot_name <- plots[[i]] |> fs::path_file() |> fs::path_ext_remove()
    plot_file <- fs::path(plots_dir, plot_name, ext = "jpg")

    p <- readRDS(plots[[i]]) +
      scale_x_continuous(breaks = seq(0, intervention_end, year_steps * 5)) +
      geom_vline(
        xintercept = c(
          calibration_end,
          restart_time,
          prep_start,
          intervention_start
        )
      )

      ggsave(
        plot_file,
        plot = p,
        width = 30, height = 20,
        unit = "cm", dpi = "retina"
      )
  }

}
