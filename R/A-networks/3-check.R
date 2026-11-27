## 3. Network Check: the fits against their targets
##
## The gate between the network fits and the epidemic calibration. Reads the
## diagnostics of `2-diagnostics.R`, compares every target statistic and
## duration of the three layers with what the fitted models simulate, writes
## the comparison, and for the HPC fits stops if anything is outside tolerance.
## A local fit's misses are reported and not enforced: it is small, its
## diagnostics are short, and nothing is concluded from it. The criteria are
## in `network_check.R`.
##
## Writes, in the diagnostics folder:
##   network_check-<context>.csv  one row per statistic and check
##   network_check-<context>.rds  the same with the verdict, which
##                                `assert_network_check()` reads
##
## Run it after `2-diagnostics.R`, for the context those diagnostics were made
## in. It simulates nothing, so it takes seconds, and it can be rerun locally
## on diagnostics copied from the HPC.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
# Set `hpc_context <- TRUE` first to check the HPC fits
if (!exists("hpc_context")) {
  hpc_context <- FALSE
}
source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)
source("R/A-networks/network_check.R", local = TRUE)

# Process ----------------------------------------------------------------------
check <- network_check(
  est_path = fs::path(est_dir, paste0("netest-", context, ".rds")),
  diag_dir = diag_dir,
  context = context,
  proposals = tergm_proposals
)

check_path <- fs::path(diag_dir, paste0("network_check-", context))
if (!is.null(check$table)) {
  write.csv(check$table, fs::path_ext_set(check_path, "csv"), row.names = FALSE)
}
saveRDS(check, fs::path_ext_set(check_path, "rds"))

message(
  "\nNetwork check, ",
  city_spec$label,
  " (",
  context,
  "): tolerance ",
  100 * check$tol,
  "%, tergm at ",
  format(tergm_proposals, big.mark = ",", scientific = FALSE),
  " proposals per step\n"
)
print_network_check(check)
message("\nSaved to \"", fs::path_ext_set(check_path, "csv"), "\"")

if (!check$pass && context == "hpc") {
  stop(
    "The network check did not pass for ",
    city_spec$label,
    ". Fix the fit or the sampling and rerun before any netsim work."
  )
}
# A local fit is small and its diagnostics are short, so a miss there is
# something to read, not a verdict. Only the HPC fits are held to the check.
if (!check$pass) {
  warning(
    "The network check did not pass for the local fits of ",
    city_spec$label,
    ". Local fits are for development and are not held to it."
  )
} else {
  message("\nThe network check passed for ", city_spec$label, ".")
}
