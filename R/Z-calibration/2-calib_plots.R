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
source("R/Z-calibration/utils-calib_plots.R", local = TRUE)

# Process ----------------------------------------------------------------------
for (out_dir in fs::dir_ls(calib_plot_dir)) generate_calib_plots(out_dir)

