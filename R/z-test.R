# Scratchpad for interactive testing before integration in a script
#
# statnet ergm.fit
# - now running with ergm 4.6.0
# - then test ergm@@i120-glm-fit

rmarkdown::render(
  "R/Z-calibration/calibration_values.Rmd",
  output_file = "calibration_report.html",
  knit_root_dir = getwd(),
  output_dir = "./"
)
