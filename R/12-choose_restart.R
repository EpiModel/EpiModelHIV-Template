##
## 12. Epidemic Model Parameter Calibration, Choice of a restart point
##

# Setup ------------------------------------------------------------------------
library("EpiModel")
library("dplyr")
library("tidyr")
source("R/00-project_settings.R")

d <- readRDS("data/intermediate/calibration/assessments_raw.rds")

source("R/utils-targets.R")

for (nme in names(targets)) {
  d[[nme]] <- d[[nme]] - targets[[nme]]
}

# Calculate RMSE
mat_d <- as.matrix(select(d, - c(batch, sim, scenario_name)))

d$scores <- apply(mat_d, 1, function(x) {
  sum(x^2, na.rm = TRUE)
})

# pick best sim
best_sim <- d %>%
  arrange(scores) %>%
  select(batch, sim) %>%
  head(1)

# Check the values manually
d %>%
  arrange(scores) %>%
  head(1) %>%
  as.list()

# Get best sim
best <- readRDS(fs::path(
  "data/intermediate/calibration",
  paste0("sim__empty_scenario__", best_sim$batch, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)
epi_num <- best$epi$num

# Remove all epi except `num`
best$epi <- list(num = epi_num)

saveRDS(best, "data/intermediate/estimates/restart.rds")
