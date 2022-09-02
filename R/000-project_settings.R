current_git_branch <- "100k"
networks_size <- 100 * 1e3

mail_user <- "aleguil@emory.edu"


calib_end <- 60 * 52
prep_start <- calib_end + 5 * 52 + 1


directories <- c(
  inputs_dir      = "data/input",
  estimates_dir   = "data/intermediate/estitmates",
  diagnostics_dir = "data/intermediate/diagnostics",
  calibration_dir = "data/intermediate/calibration"
)

# create first level variables with the directories path
# ensure the directories exist
for (i in seq_along(directories)) {
  assign(names(directories)[i], directories[i])
  if (!fs::dir_exists(directories[i])) fs::dir_create(directories[i])
}

# remove unneeded variables
rm(directories, i)
