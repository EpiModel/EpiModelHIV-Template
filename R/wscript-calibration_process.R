##
## 12. Epidemic Model Parameter Calibration, Processing
##

# Setup ------------------------------------------------------------------------
library("EpiModelHIV")
source("R/00-project_settings.R")

nsteps <- 52

# Process each file in parallel ------------------------------------------------
calib_files <- list.files(
  "data/intermediate/calibration",
  pattern = "^sim__.*rds$",
  full.names = TRUE
)

source("R/utils-targets.R")
assessments <- lapply(
  calib_files,
  process_one_calibration, # in R/utils-targets.R
  nsteps = nsteps
)

# Merge all and combine --------------------------------------------------------
assessments <- bind_rows(assessments)
saveRDS(assessments, "data/intermediate/calibration/assessments_raw.rds")

assessments <- assessments %>%
  select(- c(sim, batch)) %>%
  group_by(scenario_name) %>%
  summarise(across(
    everything(),
    list(
      q1 = ~ quantile(.x, 0.25, na.rm = TRUE),
      q2 = ~ quantile(.x, 0.50, na.rm = TRUE),
      q3 = ~ quantile(.x, 0.75, na.rm = TRUE)
    ),
    .names = "{.col}__{.fn}"
  ))

# Save the result --------------------------------------------------------------
saveRDS(assessments, "data/intermediate/calibration/assessments.rds")
