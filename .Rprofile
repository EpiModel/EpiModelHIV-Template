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
