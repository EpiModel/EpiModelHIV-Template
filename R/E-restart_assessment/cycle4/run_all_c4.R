## Run cycle 4 of the restart-variance assessment in order
##
## Requires the cycle 1 annual dataset and tables (run_all.R), and the
## cycle 3 annual dataset and tables (cycle3/run_all_c3.R). Each step runs in
## a fresh R process and the pipeline stops on the first error. Logs go to
## cycle4/results/logs/.
##
## Run from the project root: Rscript R/E-restart_assessment/cycle4/run_all_c4.R

steps <- c(
  "c4_01_prepare.R",
  "c4_02_validate.R",
  "c4_03_restart_law.R",
  "c4_04_icc_direct.R",
  "c4_05_pool_design.R"
)

for (s in steps) {
  log <- file.path("R/E-restart_assessment/cycle4/results/logs",
    sub("^(c4_[0-9]+)_.*", "\\1.log", s))
  cat(format(Sys.time()), "running", s, "\n")
  status <- system2("Rscript", file.path("R/E-restart_assessment/cycle4", s),
    stdout = log, stderr = log)
  if (status != 0) stop("Step ", s, " failed, see ", log)
}
cat(format(Sys.time()), "done\n")
