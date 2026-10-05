## Run the whole restart-variance assessment in order
##
## Each step runs in a fresh R process (as if run with Ctrl+Shift+F10) and the
## pipeline stops on the first error. Logs go to results/logs/NN.log.
##
## Run from the project root: Rscript R/E-restart_assessment/run_all.R

steps <- c(
  "01_prepare_annual.R",
  "02_validate_methods.R",
  "03_stationarity.R",
  "04_relaxation_from_x0.R",
  "05_equilibrium_structure.R",
  "06_restart_memory.R",
  "07_pool_design.R"
)

for (s in steps) {
  log <- file.path("R/E-restart_assessment/results/logs",
    sub("_.*", ".log", s))
  cat(format(Sys.time()), "running", s, "\n")
  status <- system2("Rscript", file.path("R/E-restart_assessment", s),
    stdout = log, stderr = log)
  if (status != 0) stop("Step ", s, " failed, see ", log)
}
cat(format(Sys.time()), "done\n")
