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

plots <- readRDS("./data/intermediate/calibration/calibration_plots.rds")

calib_plot_dir <- paste0("data/intermediate/calibration_plots-", context)
if (!fs::dir_exists(calib_plot_dir)) fs::dir_create(calib_plot_dir)

for (i in seq_along(plots)) {
  plot_file <- fs::path(calib_plot_dir, names(plots)[[i]], ext = "jpg")
  ggsave(
    plot_file,
    plot = plots[[i]],
    width = 30, height = 20,
    unit = "cm", dpi = "retina"
  )
}
