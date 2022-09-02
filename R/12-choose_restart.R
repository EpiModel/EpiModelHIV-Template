##
## 11. Epidemic Model Parameter Calibration, Local evaluation
##

# Setup ------------------------------------------------------------------------
library(EpiModel)
library(dplyr)
library(tidyr)
source("R/000-project_settings.R")

d <- readRDS(fs::path(calibration_dir, "assessments_raw.rds"))

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
  calibration_dir,
  paste0("sim__empty_scenario__", best_sim$batch, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)
epi_num <- best$epi$num

# Remove all epi except `num`
best$epi <- list(num = epi_num)

saveRDS(best, fs::path(estimates_dir, "restart.rds"))
