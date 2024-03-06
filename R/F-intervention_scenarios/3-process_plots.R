## 3. Intervention Scenarios Process Plots
##
## Make the plots using the results of the simulations from the previous step
## locally or on the HPC (see `workflow-interventions.R`)

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/F-intervention_scenarios/outcomes.R", local = TRUE)

# Process ----------------------------------------------------------------------

scenarios_tibble_dir <- fs::path(scenarios_dir, "merged_tibbles")
scenarios_info <- EpiModelHPC::get_scenarios_tibble_infos(scenarios_tibble_dir)

d_ref <- make_d_ref(fs::path(scenarios_tibble_dir, "df__test_1_treat_1.rds"))

d_ls <- future.apply::future_lapply(
  seq_len(nrow(scenarios_info)),
  \(i) process_one_scenario_plots(scenarios_info[i, ], d_ref)
)

d_plots <- dplyr::bind_rows(d_ls)
glimpse(d_plots)

library(ggplot2)
theme_set(theme_light())

ggplot(d_plots, aes(x = test, y = treat, fill = cml_pia_b, z = cml_pia_b)) +
  geom_raster(interpolate = TRUE) +
  geom_contour(col = "white", alpha = 0.5, lwd = 0.5, position = "jitter") +
  viridis::scale_fill_viridis(
    discrete = FALSE,
    alpha = 1,
    option = "B",
    direction = 1,
    labels = scales::label_percent(1)
  )
