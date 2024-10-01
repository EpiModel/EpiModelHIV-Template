# Scratchpad for interactive testing before integration in a script

source("R/shared_variables.R", local = TRUE)

library(dplyr)
library(EpiModel)

d_calib <- readRDS("./data/run/calibration/merged_tibbles/df__empty_scenario.rds")

d_outs <- EpiModelHIV::mutate_calibration_targets(d_calib) |>
  mutate(sim = as.integer(as.factor(paste0(batch_number, "_", sim)))) |>
  as.epi.data.frame()

unique(d_outs$sim)

targets <- EpiModelHIV::get_calibration_targets()
targets["num"] <- 1e4
colors <-  c("steelblue", "firebrick", "seagreen")
text_pos <- max(d_outs$time) - 500
par(mar = c(3, 3, 1, 1), mgp = c(2, 1, 0))

cur_targs <- paste0("cc.dx.", c("B", "H", "W"))
plot(
  d_outs,
  y = cur_targs,
  legend = TRUE,
  ylim = c(0.7, 1),
  ylab = "Proportion",
  xlab = "Calibration Weeks"
)
x <- round(colMeans(tail(d_outs[, cur_targs], 52)), 3)
abline(h = targets[cur_targs], col = colors, lty = 2)
text(text_pos, targets[cur_targs[1]] + 0.01, x[1], col = colors[1])
text(text_pos, targets[cur_targs[2]] + 0.01, x[2], col = colors[2])
text(text_pos, targets[cur_targs[3]] + 0.01, x[3], col = colors[3])

races <- c("B", "H", "W")
calib_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", races),
    ylab = "Proportion of HIV+ Diagnosed",
    text_offset = 0.01
  ),
  cc.linked1m = list(
    names = paste0("cc.linked1m.", races),
    ylab = "Proportion of Diagnosed Linked to Care",
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
    ylab = "Proportion",
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

for (p in calib_plot_infos) {
  make_calib_plot(d_outs, p)
  Sys.sleep(1)
}
