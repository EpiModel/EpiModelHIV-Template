## 2. Calibration Plots
##
## Generate the calibration plots using the data produced by the
## `process_calib_plots.R` script. This is usually run as part of the restart
## point workflow. The calibration plot data must be downloaded from the HPC and
## be stored to: `fs::path(calib_plot_dir, "data")`

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

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
      )
    )

  ggsave(
    plot_file,
    plot = p,
    width = 30, height = 20,
    unit = "cm", dpi = "retina"
  )
}
