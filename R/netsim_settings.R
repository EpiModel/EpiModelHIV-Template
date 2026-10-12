## Default settings for `netsim`
##
## This script should not be run directly. But `sourced` from other scripts
## using the `netsim` function.
##
## Requires:
##   - `context` (from z-context.R)
##   -  paths from shared_variables.R
## Creates:  `param`, `init`, `path_to_est`, `path_to_restart`, `params_df`

#' Read the model parameters: package defaults plus project overrides.
#'
#' Starts from `model_parameters.csv` shipped with the loaded EpiModelHIV (the
#' installed package, or your local clone after `load_local_EpiModelHIV()`),
#' then replaces the rows named in the project file
#' `data/input/model_parameters.csv`. Empty cells keep the package value, so
#' a row with just the `param` and `value` cells filled in is enough.
#'
#' Stops if the project file names a parameter the package does not have, so a
#' stale or misspelled override fails loudly instead of being ignored.
read_model_params <- function(
    project_csv = fs::path(input_dir, "model_parameters.csv")) {
  package_csv <- system.file("model_parameters.csv", package = "EpiModelHIV")
  if (!nzchar(package_csv)) {
    stop("EpiModelHIV does not provide `model_parameters.csv`. ",
         "Load EpiModelHIV before sourcing this file.")
  }
  params <- read.csv(package_csv, colClasses = "character")
  overrides <- read.csv(project_csv, colClasses = "character")

  if (!all(c("param", "value") %in% names(overrides))) {
    stop("`", project_csv, "` must have at least `param` and `value` columns.")
  }
  dups <- unique(overrides$param[duplicated(overrides$param)])
  if (length(dups) > 0) {
    stop("`", project_csv, "` sets these parameters more than once: `",
         paste0(dups, collapse = "`, `"), "`")
  }
  unknown <- setdiff(overrides$param, params$param)
  if (length(unknown) > 0) {
    stop(
      "\n  `", project_csv, "` overrides parameters that EpiModelHIV ",
      utils::packageVersion("EpiModelHIV"), " does not have:\n    `",
      paste0(unknown, collapse = "`, `"), "`\n",
      "  They were probably renamed or removed in the package. Fix or delete\n",
      "  these rows. The package defaults are in:\n    ", package_csv
    )
  }

  rows <- match(overrides$param, params$param)
  for (col in setdiff(intersect(names(overrides), names(params)), "param")) {
    set <- !is.na(overrides[[col]]) & nzchar(overrides[[col]])
    params[rows[set], col] <- overrides[[col]][set]
  }
  params
}

# Load network statistics and estimation outputs from Chapter A
epistats <- readRDS(fs::path(est_dir, paste0("epistats-", context, ".rds")))
netstats <- readRDS(fs::path(est_dir, paste0("netstats-", context, ".rds")))
path_to_est <- fs::path(est_dir, paste0("netest-", context, ".rds"))
path_to_restart <- fs::path(est_dir, paste0("restart-", context, ".rds"))

# Package defaults with the project overrides applied
params_df <- read_model_params() |>
  dplyr::select(param, value, type)

# `netsim` Parameters
param <- param.net(
  data.frame.params   = params_df,
  netstats            = netstats,
  epistats            = epistats,
  prep.start          = prep_start,
  riskh.start         = prep_start - year_steps
)

# Initial conditions (default prevalence initialized in epistats).
# For models without bacterial STIs, these must be initialized
# here with non-zero values.
init <- init_msm(
  prev.gono.rect = 0.1,
  prev.gono.uret = 0.1,
  prev.chla.rect = 0.1,
  prev.chla.uret = 0.1,
  prev.syph      = 0.1
)

# Flags to now weather each disease is enabled
has_sti <- c(
  gono = init$prev.gono.rect > 0 | init$prev.gono.uret > 0,
  chla = init$prev.chla.rect > 0 | init$prev.chla.uret > 0,
  syph = init$prev.syph > 0
)
