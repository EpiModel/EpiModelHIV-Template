# Utility
replace_join <- function(orig, new, by) {
  out <- dplyr::left_join(orig, new, by = by, suffix = c("__ditch_me", ""))
  out[names(orig)]
}

# Setup
library(EpiModelHIV)
hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)

# load elements
calib_object <- swfcalib:::load_calib_object(calib_object)
default_proposal <- swfcalib:::get_default_proposal(calib_object)

scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(default_proposal)
param_sc <- EpiModel::use_scenario(param, scenario)

prm <- c("epistats", "netstats", ".param.updater.list", ".scenario.id")
param_sc[prm] <- NULL

updt_param <- EpiModel::param.net_to_table(param_sc)

# param_df loaded by netsim_settings
new_params <- replace_join(param_df, updt_param, by = c("param", "type"))
readr::write_csv(
  new_params,
  fs::path(swfcalib:::get_root_dir(calib_object), "params.csv")
)
