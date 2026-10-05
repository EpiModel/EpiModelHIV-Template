## Run cycle 3 of the restart-variance assessment in order
##
## Requires the cycle 1 annual dataset (R/E-restart_assessment/run_all.R,
## step 01) and cycle 1 tables. Each step runs in a fresh R process and the
## pipeline stops on the first error. Logs go to cycle3/results/logs/.
##
## Run from the project root: Rscript R/E-restart_assessment/cycle3/run_all_c3.R

steps <- c(
  "c3_01_prepare.R",
  "c3_02_validate.R",
  "c3_03_same_law.R",
  "c3_04_cold_start.R",
  "c3_05_workflow.R",
  "c3_06_replication.R"
)

for (s in steps) {
  log <- file.path("R/E-restart_assessment/cycle3/results/logs",
    sub("^(c3_[0-9]+)_.*", "\\1.log", s))
  cat(format(Sys.time()), "running", s, "\n")
  status <- system2("Rscript", file.path("R/E-restart_assessment/cycle3", s),
    stdout = log, stderr = log)
  if (status != 0) stop("Step ", s, " failed, see ", log)
}
cat(format(Sys.time()), "done\n")
