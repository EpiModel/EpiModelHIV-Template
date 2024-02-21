## Intervention Scenarios outcomes
##
## Define helper functions to create the scenarios outcome variables and to
## combine them into digestible tibbles
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/F-intervention_scenarios/` directory.

# create the elements of the outcomes step by step
mutate_outcomes <- function(d) {
  d |>
    mutate(
      lst_ir100_b = ir100.B,
      lst_ir100_h = ir100.H,
      lst_ir100_w = ir100.W,
      cml_incid_b = incid.B,
      cml_incid_h = incid.H,
      cml_incid_w = incid.W
    )
}

make_d_ref <- function(file_path) {
  readRDS(file_path) |>
    mutate_outcomes() |>
    filter(time >= max(time) - 10 * 52) |>
    select(batch_number, sim, starts_with("cml_incid")) |>
    group_by(batch_number, sim) |>
    summarize(across(everything(), \(x) sum(x, na.rm = TRUE))) |>
    ungroup() |>
    select(-c(batch_number, sim)) |>
    summarize(across(everything(), \(x) median(x, na.rm = TRUE)))
}

mutate_nia_pia <- function(d, ref_val, var, var_nia, var_pia) {
  d[[var_nia]] <- ref_val - d[[var]]
  d[[var_pia]] <- d[[var_nia]] / ref_val
  d
}

mutate_pia <- function(d, var, var_nia, var_pia) {
  d[[var_pia]] <- d[[var_nia]] / (d[[var_nia]] + d[[var]])
  d
}

# make the outcomes calculated on the same year
make_last_year_outcomes <- function(d) {
  d |>
    filter(time >= max(time) - 52) |>
    group_by(scenario_name, batch_number, sim) |>
    summarise(across(starts_with("lst_"), \(x) mean(x, na.rm = TRUE))) |>
    ungroup()
}

# make the outcomes cumulative over the intervention period
make_cumulative_outcomes <- function(d) {
  d |>
    filter(time >= intervention_start) |>
    group_by(scenario_name, batch_number, sim) |>
    summarise(across(starts_with("cml_"), \(x) sum(x, na.rm = TRUE))) |>
    ungroup()
}

# each batch of sim is processed in turn
# the output is a data frame with one row per simulation in the batch
# each simulation can be uniquely identified with `scenario_name`,
# `batch_number` and `sim` (all 3 are needed)
process_one_scenario <- function(scenario_infos, d_ref) {
  d_sim <- readRDS(scenario_infos$file_path)
  d_sim <- mutate_outcomes(d_sim)
  d_sim <- mutate(d_sim, scenario_name = scenario_infos$scenario_name)

  d_last <- make_last_year_outcomes(d_sim)
  d_cum <- make_cumulative_outcomes(d_sim)

  d <- left_join(d_last, d_cum, by = c("scenario_name", "batch_number", "sim"))

  for (pop in c("b", "h", "w")) {
    d <- mutate_nia_pia(
      d,
      d_ref[[paste0("cml_incid_", pop)]],
      paste0("cml_incid_", pop),
      paste0("cml_nia_", pop),
      paste0("cml_pia_", pop)
    )
  }

  d
}

process_one_scenario_plots <- function(scenario_infos, d_ref) {
  d_sim <- process_one_scenario(scenario_infos, d_ref)
  d_sim |>
    select(scenario_name, starts_with("cml_pia")) |>
    separate_wider_delim(scenario_name, "_", names = c(NA, "test", NA, "treat")) |>
    mutate(test = as.numeric(test), treat = as.numeric(treat))
}

