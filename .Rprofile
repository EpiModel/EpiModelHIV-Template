# 0. Disable `renv` sandboxing if non-interactive
if (!interactive()) options(renv.config.sandbox.enabled = FALSE)

# 1. renv package management
if (dir.exists("renv/")) {
  if (file.exists("renv/activate.R")) {
    source("renv/activate.R")
  } else {
    cat(
      "* renv may have been incompletely set up.\n",
      "  Run renv::init(bare = TRUE) to continue\n"
    )
  }
  if (interactive()) renv::status()
} else {
  cat(
    "* Run renv::init(bare = TRUE) to install the R packages for this project\n"
  )
}

# 2. directory structure
.folder.struct <- c(
  "data/input",
  "data/run/calibration",
  "data/run/diagnostics",
  "data/run/estimates",
  "data/run/scenarios",
  "data/output",
  "workflows"
)
for (.folder in .folder.struct) {
  if (!dir.exists(.folder)) dir.create(.folder, recursive = TRUE)
}
rm(.folder.struct, .folder)

# 3. Helpful aliases
rs <- function() .rs.restartR()
si <- function() sessioninfo::session_info()

# 4. Standard options
options(deparse.max.lines = 5)

#' Load EpiModelHIV-p from the local development clone.
#'
#' Reads the `EPIMODELHIV_DIR` environment variable (set in the project's
#' `.Renviron`) and calls `pkgload::load_all()` on it. If that variable is
#' missing or does not point to an existing folder, the function stops with
#' instructions to set it up.
load_local_EpiModelHIV <- function() {
  dev_dir <- Sys.getenv("EPIMODELHIV_DIR", unset = "")
  if (!dir.exists(dev_dir)) {
    stop(
      "\n",
      "  The path to your local copy of EpiModelHIV-p is not correctly set.\n",
      "  Define the `EPIMODELHIV_DIR` variable in '.Renviron'.\n\n",
      "  Open '.Renviron' with: \n",
      "    `usethis::edit_r_environ(\"project\")`.\n\n",
      "  Write in it: \n",
      "    EPIMODELHIV_DIR=\"<path to the cloned repository>\"\n\n",
      "  then save the file and restart R."
    )
  }
  message("Loading EpiModelHIV-p from: ", dev_dir)
  pkgload::load_all(dev_dir)
}

