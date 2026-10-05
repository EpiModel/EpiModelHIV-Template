## Run cycle 2 of the restart-variance assessment in order
##
## Requires the cycle 1 annual dataset (R/E-restart_assessment/run_all.R,
## step 01) and cycle 1 tables. Each step runs in a fresh R process and the
## pipeline stops on the first error. Logs go to cycle2/results/logs/.
##
## Run from the project root: Rscript R/E-restart_assessment/cycle2/run_all_c2.R

steps <- c(
  "c2_01_provenance.R",
  "c2_02_project_outcomes.R",
  "c2_03_robustness.R",
  "c2_04_design.R",
  "c2_05_selection.R"
)

for (s in steps) {
  log <- file.path("R/E-restart_assessment/cycle2/results/logs",
    sub("^(c2_[0-9]+)_.*", "\\1.log", s))
  cat(format(Sys.time()), "running", s, "\n")
  status <- system2("Rscript", file.path("R/E-restart_assessment/cycle2", s),
    stdout = log, stderr = log)
  if (status != 0) stop("Step ", s, " failed, see ", log)
}
cat(format(Sys.time()), "done\n")
