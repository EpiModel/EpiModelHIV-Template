current_git_branch <- "100k"
networks_size <- 100 * 1e3

directories <- c(
  inputs_dir      = "data/input",
  estimates_dir   = "data/intermediate/estitmates",
  diagnostics_dir = "data/intermediate/diagnostics"
)

# create first level variables with the directories path
# ensure the directories exist
for (i in seq_along(directories)) {
  assign(names(directories)[i], directories[i])
  if (!fs::dir_exists(directories[i])) fs::dir_create(directories[i])
}

# remove unneeded variables
rm(directories, i)
