##
## 12. Epidemic Model Parameter Calibration, Processing
##

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

nsteps <- 52

# Create the output directory
calib_dir <- "data/output/calibration"

# Process each file in parallel ------------------------------------------------
calib_files <- list.files(
  calib_dir,
  pattern = "^simcalib__.*rds$",
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
saveRDS(assessments, paste0(calib_dir, "/assessments.rds"))

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
  # this last bloc calculate the q1, median and q3 for all of the variables

# Save the result --------------------------------------------------------------
saveRDS(assessments, paste0(calib_dir, "/assessments.rds"))
