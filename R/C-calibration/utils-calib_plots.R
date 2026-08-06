library(dplyr)
library(EpiModel)

make_calib_plot <- function(d, plot_info, year_steps = 52) {
  targets <- project_calibration_targets()
  targets["num"] <- 1e5
  colors <-  c("steelblue", "firebrick", "seagreen")
  text_pos <- max(d$time) - 500
  par(mar = c(3, 3, 1, 1), mgp = c(2, 1, 0))
  offset <- plot_info$text_offset
  cur_targs <- plot_info$names

  d <- as.epi.data.frame(d)

  plot(
    d,
    xaxt = "n",
    y = cur_targs,
    legend = TRUE,
    ylab = plot_info$ylab,
    xlab = "Calibration Years"
  )
  axis(1, seq(0, max(d$time), 10 * year_steps),
       labels = seq(0, max(d$time), 10 * year_steps) / year_steps)

  x <- d |>
    filter(time > max(time) - year_steps) |>
    select(sim, all_of(cur_targs)) |>
    group_by(sim) |>
    summarise(across(everything(), mean)) |>
    select(-sim) |>
    summarise(across(everything(), median)) |>
    unlist()

  ts <- targets[cur_targs]
  abline(h = ts, col = colors, lty = 2)
  text(text_pos, ts + offset, plot_info$fmt_target(x), col = colors)
  text(1, ts - offset, plot_info$fmt_target(ts), col = colors)
}

races <- c("B", "H", "W")
calib_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", races),
    ylab = "Proportion",
    text_offset = 0.01,
    fmt_target = scales::percent_format(0.1)
  ),
  cc.vsupp = list(
    names = paste0("cc.vsupp.", races),
    ylab = "Proportion",
    text_offset = 0.005,
    fmt_target = scales::percent_format(0.1)
  ),
  i.prev.dx = list(
    names = paste0("i.prev.dx.", races),
    ylab = "Proportion",
    text_offset = 0.01,
    fmt_target = scales::percent_format(0.1)
  ),
  ir100.sti = list(
    names = c("ir100.gono", "ir100.chla", "ir100.syph"),
    ylab = "Infection Rate per 100 PYAR",
    text_offset = 0.3,
    fmt_target = scales::number_format(0.1)
  ),
  cc.prep = list(
    names = paste0("cc.prep.", races),
    ylab = "Proportion",
    text_offset = 0.005,
    fmt_target = scales::percent_format(0.1)
  ),
  disease.mr100 = list(
    names = "disease.mr100",
    ylab = "Proportion",
    text_offset = 0.01,
    fmt_target = scales::percent_format(0.1)
  ),
  num = list(
    names = "num",
    ylab = "Population",
    text_offset = 500,
    fmt_target = scales::number_format(1)
  )
)

rm(races)
