current_git_branch <- "100k"
networks_size <- 100 * 1e3

# Directory to store the network estimations
estimates_directory <- "data/intermediate/estitmates"
if (!fs::dir_exists(estimates_directory))
  fs::dir_create(estimates_directory)

# Directory to store the network diagnostics
diagnostics_directory <- "data/intermediate/diagnostics"
if (!fs::dir_exists(diagnostics_directory))
  fs::dir_create(diagnostics_directory)
