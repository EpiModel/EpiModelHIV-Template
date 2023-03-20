##
## 22. Epidemic Model Restart Point, Choice of the best restart point
##

# Libraries --------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")
library("tidyr")

# Settings ---------------------------------------------------------------------
#
# Choose the right context: "local" when choosing the restart point from local
# runs, "hpc" otherwise. For "hpc", this
#   assumes that you downloaded the "assessments_raw.rds" files from the HPC.
context <- if (!exists("context")) c("local", "hpc")[1] else context
source("R/utils-0_project_settings.R")
source("R/utils-default_inputs.R", local = TRUE) # generate `path_to_restart`

d <- readRDS("data/intermediate/calibration/assessments_raw.rds")

source("R/utils-targets.R")

for (nme in names(targets)) {
  if (nme %in% names(d)) {
    d[[nme]] <- d[[nme]] - targets[[nme]]
  }
}

# Calculate RMSE
mat_d <- as.matrix(select(d, - c(batch_number, sim, scenario_name)))

d$scores <- apply(mat_d, 1, function(x) {
  sum(x^2, na.rm = TRUE)
})

# pick best sim
best_sim <- d %>%
  arrange(scores) %>%
  select(batch_number, sim) %>%
  head(1)

# Check the values manually
d %>%
  arrange(scores) %>%
  head(1) %>%
  as.list()

# Get best sim
best <- readRDS(fs::path(
  "data/intermediate/calibration",
  paste0("sim__empty_scenario__", best_sim$batch_number, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)
epi_num <- best$epi$num

# Remove all epi except `num`
best$epi <- list(num = epi_num)

saveRDS(best, path_to_restart)
