# 1. renv package management
if (dir.exists("renv/")) {
  if (file.exists("renv/activate.R")) {
    source("renv/activate.R")
  } else {
    cat("* renv may have been incompletely set up. Run renv::init() to continue\n")
  }
  if (interactive()) {
    renv::status()
  }
} else {
  cat("* Run renv::init() to install the R packages for this project\n")
}

# 2. directory structure
if (!dir.exists("data/input/")) {
  dir.create("data/input/", recursive = TRUE)
}
if (!dir.exists("data/output/")) {
  dir.create("data/output/")
}
if (!dir.exists("out/")) {
  dir.create("out/")
}
if (!dir.exists("workflows/")) {
  dir.create("workflows/")
}

# 3. Helpful aliases
rs <- function() .rs.restartR()

# 4. Standard options
options(deparse.max.lines = 5)
