# Libraries --------------------------------------------------------------------
library(ggplot2)
#
# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
theme_set(theme_classic())

plots <- fs::dir_ls(fs::path(calib_plot_dir, "data"))
plots_dir <- fs::path(calib_plot_dir, "plots")

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
    ))

  ggsave(
    plot_file,
    plot = p,
    width = 30, height = 20,
    unit = "cm", dpi = "retina"
  )
}
