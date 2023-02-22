library("ggplot2")

# Settings ---------------------------------------------------------------------
context <- c("local", "hpc")[1]

source("R/utils-0_project_settings.R")

plots <- readRDS("./data/intermediate/calibration/calibration_plots.rds")

calib_plot_dir <- paste0("data/intermediate/calibration_plots-", context)
if (!fs::dir_exists(calib_plot_dir)) fs::dir_create(calib_plot_dir)

for (i in seq_along(plots)) {
  theme_set(theme_classic())
  plot_file <- fs::path(calib_plot_dir, names(plots)[[i]], ext = "jpg")
  ggsave(
    plot_file,
    plot = plots[[i]],
    width = 30, height = 20,
    unit = "cm", dpi = "retina"
  )
}
