# Scratchpad for interactive testing before integration in a script
#
# statnet ergm.fit
# - now running with ergm 4.6.0
# - then test ergm@@i120-glm-fit

source("R/shared_variables.R", local = TRUE)

library(dplyr)
library(EpiModel)

d_calib <- readRDS("./data/run/calibration/merged_tibbles/df__empty_scenario.rds")

d_outs <- EpiModelHIV::mutate_calibration_targets(d_calib) |>
  mutate(sim = as.integer(as.factor(paste0(batch_number, "_", sim)))) |>
  as.epi.data.frame()

races <- c("B", "H", "W")
calib_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", races),
    ylab = "Proportion",
    text_offset = 0.01
  ),
  cc.linked1m = list(
    names = paste0("cc.linked1m.", races),
    ylab = "Proportion",
    text_offset = 0.005
  ),
  cc.vsupp = list(
    names = paste0("cc.vsupp.", races),
    ylab = "Proportion",
    text_offset = 0.005
  ),
  i.prev.dx = list(
    names = paste0("i.prev.dx.", races),
    ylab = "Proportion",
    text_offset = 0.01
  ),
  ir100.sti = list(
    names = c("ir100.gc", "ir100.ct"),
    ylab = "Infection Rate per 100 PYAR",
    text_offset = 0.3
  ),
  cc.prep = list(
    names = paste0("cc.prep.", races),
    ylab = "Proportion",
    text_offset = 0.005
  ),
  disease.mr100 = list(
    names = "disease.mr100",
    ylab = "Proportion",
    text_offset = 0.01
  ),
  num = list(
    names = "num",
    ylab = "Population",
    text_offset = 500
  )
)

make_calib_plot <- function(d, plot_info) {
  targets <- EpiModelHIV::get_calibration_targets()
  targets["num"] <- 1e5
  colors <-  c("steelblue", "firebrick", "seagreen")
  text_pos <- max(d$time) - 500
  par(mar = c(3, 3, 1, 1), mgp = c(2, 1, 0))
  offset <- plot_info$text_offset
  cur_targs <- plot_info$names
  plot(
    d,
    y = cur_targs,
    legend = TRUE,
    ylab = plot_info$ylab,
    xlab = "Calibration Weeks"
  )
  x <- round(colMeans(tail(d_outs[, cur_targs], 52)), 3)
  abline(h = targets[cur_targs], col = colors, lty = 2)
  for (i in seq_along(plot_info$names))
    text(text_pos, targets[cur_targs[i]] + offset, x[i], col = colors[i])
}

if (!fs::dir_exists(calib_plot_dir)) fs::dir_create(calib_plot_dir)
for (i in seq_along(calib_plot_infos)) {
  p <- calib_plot_infos[[i]]
  jpeg(
    file = fs::path(calib_plot_dir, names(calib_plot_infos)[[i]], ext = "jpg"),
    width = 9, height = 5.5,
    units = "in", res = 250
  )
  make_calib_plot(d_outs, p)
  dev.off()
}

# calib tables:
#
#  added med_diag_delay__B/H/W -> supp table 10
#  rm dx delay figure? (sup fig 5)
#  added med_linked_delay__B/H/W -> sup table 11
#  sup table 12: calculated from rate
#
#  table sup 13 - STI modifiers??
#  ==> legacy: I guess they come from a
