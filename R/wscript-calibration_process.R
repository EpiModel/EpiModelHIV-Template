##
## 12. Epidemic Model Parameter Calibration, Processing
##

# Setup ------------------------------------------------------------------------
library("EpiModelHIV")
source("R/utils-0_project_settings.R")

# where the calibration files are stored
source_dir <- "data/intermediate/calibration/"
file_name_list <- fs::dir_ls(source_dir, regexp = "/sim__.*rds$", type = "file")

name_elts <- fs::path_file(file_name_list)
name_elts <- fs::path_ext_remove(name_elts)
name_elts <- strsplit(name_elts, split = "__")

scenario_name_list <- vapply(name_elts, function(x) x[2], "")
batch_num_list <- vapply(name_elts, function(x) x[3], "")

assessments <- Map(
  process_one_calibration,
  file_name = file_name_list,
  scenario_name = scenario_name_list,
  batch_num = batch_num_list
)

assessments_raw <- dplyr::bind_rows(assessments)
saveRDS(assessment_raw, fs::path(output_dir, "assessments_raw.rds"))

assessment <- summarise_calibration(assessment_raw)

saveRDS(assessment, fs::path(output_dir, "assessments.rds"))
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

library(dplyr)
process_one_calibration <- function(file_name, scenario_name, batch_num) {
  sim <- readRDS(file_name)
  d <- as_tibble(sim) %>%
    mutate(
      scenario_name = scenario_name,
      batch_num = batch_num
    ) %>%
   mutate(
    cc.dx.B         = i_dx___B / i___B,
    cc.dx.H         = i_dx___H / i___H,
    cc.dx.W         = i_dx___W / i___W,
    cc.linked1m.B   = linked1m___B / i_dx___B,
    cc.linked1m.H   = linked1m___H / i_dx___H,
    cc.linked1m.W   = linked1m___W / i_dx___W,
    cc.vsupp.B      = i_sup___B / i_dx___B,
    cc.vsupp.H      = i_sup___H / i_dx___H,
    cc.vsupp.W      = i_sup___W / i_dx___W,
    gc_s            = gc_s___B + gc_s___H + gc_s___W,
    ir100.gc        = incid.gc / gc_s * 5200,
    ct_s            = ct_s___B + ct_s___H + ct_s___W,
    ir100.ct        = incid.ct / ct_s * 5200,
    i.prev.dx.B     = i_dx___B / n___B,
    i.prev.dx.H     = i_dx___H / n___H,
    i.prev.dx.W     = i_dx___W / n___W,
    prep_users      = s_prep___B + s_prep___H + s_prep___W,
    prep_elig       = s_prep_elig___B + s_prep_elig___H + s_prep_elig___W,
    prep_prop       = prep_users / prep_elig,
    prep_prop_ret1y = prep_ret1y___ALL / lag(prep_startat___ALL, 52),
    prep_prop_ret2y = prep_ret2y___ALL / lag(prep_startat___ALL, 104)
  )

}
