## Run cycle 5 of the restart-variance assessment in order
##
## Requires the cycle 4 annual dataset (cycle4/run_all_c4.R) and the merged
## scenario runs in data/run/variance_scenarios/ (workflow
## R/C-new_calibration/workflow-variance_scenarios.R). Each step runs in a
## fresh R process and the pipeline stops on the first error. Logs go to
## cycle5/results/logs/.
##
## Run from the project root: Rscript R/E-restart_assessment/cycle5/run_all_c5.R

steps <- c(
  "c5_01_prepare.R",
  "c5_02_validate.R",
  "c5_03_effects.R",
  "c5_04_sti_threshold.R",
  "c5_05_relaxation.R"
)

for (s in steps) {
  log <- file.path("R/E-restart_assessment/cycle5/results/logs",
    sub("^(c5_[0-9]+)_.*", "\\1.log", s))
  cat(format(Sys.time()), "running", s, "\n")
  status <- system2("Rscript", file.path("R/E-restart_assessment/cycle5", s),
    stdout = log, stderr = log)
  if (status != 0) stop("Step ", s, " failed, see ", log)
}
cat(format(Sys.time()), "done\n")
