# Scratchpad for interactive testing before integration in a script

mft <- function() {
  library("EpiModelHIV")
  library("dplyr")

  source("./R/utils-0_project_settings.R")
  context <- "hpc"
  source("./R/utils-default_inputs.R", local = TRUE)

  path_to_est
}

mft()

callr::r(mft)

future::plan("multicore", workers = 2)
future.apply::future_lapply(1:2, function(x) mft())
