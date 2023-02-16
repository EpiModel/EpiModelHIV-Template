
library("EpiModelHIV")
library("dplyr")
library("tidyr")

# Settings ---------------------------------------------------------------------
#
# Choose the right context: "local" when choosing the restart point from local
# runs, "hpc" otherwise. For "hpc", this
#   assumes that you downloaded the "assessments_raw.rds" files from the HPC.
context <- c("local", "hpc")[1]
source("R/utils-0_project_settings.R")
source("R/utils-default_inputs.R") # generate `path_to_restart`

source("./R/utils-targets.R")

# process
# - all files?
# - all at once?
# - save results as 1 rds per target group
# - process by batch then merge

process_one_plot_calib_batch <- function(scenario_infos) {
  # mutate calib targets
  # select only calib targets
  # add scenario / batch cols
  # save n rds file:
  #   - plot__cc.dx__scenario_name__batch_num.rds
  #   - plot__cc.linked1m__scenario_name__batch_num.rds
}

make_this.target_plot <- function() {
  # load all data
  # use the plot function
}

plot_this.target <- function(d) {
  ggplot(d, aes(x = time, y = target, col = group, fill = group))
}



# plot by target group
