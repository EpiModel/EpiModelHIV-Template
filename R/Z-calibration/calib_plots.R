library(dplyr)
library(tidyr)
library(ggplot2)

# make calibraion plots --------------------------------------------------------
source("./R/shared_variables.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
calib_steps <- year_steps
path_calibs <- fs::path(calib_dir, "merged_tibbles", "df__empty_scenario.rds")
plots_dir <- "data/intermediate/calibration_plots/"
if (!fs::dir_exists(plots_dir)) fs::dir_create(plots_dir)

modulo_steps <- 2

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

d_calibs <- readRDS(path_calibs) |>
  EpiModelHIV::mutate_calibration_targets(year_steps) |>
  dplyr::select(batch_number, sim, time, dplyr::any_of(names(targets)))



for (plot_name in names(targets_plot_infos)) {
  plot_infos <- targets_plot_infos[[plot_name]]
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
    saveRDS(p, fs::path(plots_dir, paste0(plot_name, ".rds")))
}

readRDS("./data/intermediate/calibration_plots/cc.vsupp.rds")
