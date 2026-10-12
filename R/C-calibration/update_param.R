# Utility
replace_join <- function(orig, new, by) {
  out <- dplyr::left_join(orig, new, by = by, suffix = c("__ditch_me", ""))
  out[names(orig)]
}

# Setup
library(EpiModelHIV)
hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
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
new_params <- replace_join(params_df, updt_param, by = c("param", "type"))

# Keep only the project overrides: the rows already in the project file plus
# the calibrated parameters. Copy the result over
# "data/input/model_parameters.csv".
override_names <- c(
  read.csv(fs::path(input_dir, "model_parameters.csv"))$param,
  names(default_proposal)
)
new_params <- new_params[new_params$param %in% override_names, ]

write.csv(
  new_params,
  fs::path(swfcalib:::get_root_dir(calib_object), "params.csv"),
  row.names = FALSE
)
