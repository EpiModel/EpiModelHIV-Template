## Process Calibration Plots
##
## Generate a the calibration plots objects (not the images) on the HPC. And
## make the data available to be downloaded for the image generation on the
## local machine. *Generating the actual images on the HPC is complex as it is a
## headless environment*
##
## This script should be called by the restart_point workflow

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)

source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)
source("R/Z-calibration/utils-calib_plots.R", local = TRUE)

calib_steps <- year_steps

# provide var `scenario`
d_path <- fs::path(calib_dir, "merged_tibbles", paste0("df__", scenario, ".rds"))
out_dir <- fs::path(calib_plot_dir, scenario)
if (!fs::dir_exists(out_dir)) fs::dir_create(out_dir)

calib_plot_infos <- list(
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
## rm later
  sti_prev = list(
    names = c("gc_prev", "ct_prev"),
    window_size = 13
  ),
## done rm
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
  ),
  num = list(
    names = "num",
    window_size = 13
  )
)

make_calib_plots(d_path, out_dir, calib_plot_infos, year_steps)
