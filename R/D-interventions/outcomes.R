## Intervention Scenarios outcomes
##
## Define helper functions to create the scenarios outcome variables and
## to combine them into digestible tibbles.
##
## This script should not be run directly. But `sourced` from other
## scripts within the `R/D-interventions/` directory.
##
## Naming convention:
##   lst_  = last-year average (mean over final `year_steps`)
##   cml_  = cumulative (sum over intervention period)
##   _nia  = Number of Infections Averted (vs. baseline)
##   _pia  = Proportion of Infections Averted (vs. baseline)
##   _b/_h/_w = population: Black, Hispanic, White

# Rename raw epi trackers to standardized outcome names
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

# Build a reference (baseline) summary from one scenario. This is used
# to compute NIA/PIA: how many infections were averted compared to the
# baseline scenario. Keeps all `cml_` outcomes.
make_d_ref <- function(file_path) {
  readRDS(file_path) |>
    mutate_outcomes() |>
    filter(time >= max(time) - 10 * year_steps) |>
    select(sim, starts_with("cml_")) |>
    group_by(sim) |>
    summarize(
      across(everything(), \(x) sum(x, na.rm = TRUE))
    ) |>
    ungroup() |>
    select(sim) |>
    summarize(
      across(everything(), \(x) median(x, na.rm = TRUE))
    )
}

# NIA = ref - intervention; PIA = NIA / ref
mutate_nia_pia <- function(
    d, ref_val, var, var_nia, var_pia) {
  d[[var_nia]] <- ref_val - d[[var]]
  d[[var_pia]] <- d[[var_nia]] / ref_val
  d
}

# Average last-year outcomes (lst_) over final `year_steps`
make_last_year_outcomes <- function(d) {
  d |>
    filter(time >= max(time) - year_steps) |>
    group_by(scenario_name, sim) |>
    summarise(
      across(starts_with("lst_"), \(x) mean(x, na.rm = TRUE))
    ) |>
    ungroup()
}

# Sum cumulative outcomes (cml_) over intervention period
make_cumulative_outcomes <- function(d) {
  d |>
    filter(time >= intervention_start) |>
    group_by(scenario_name, sim) |>
    summarise(
      across(starts_with("cml_"), \(x) sum(x, na.rm = TRUE))
    ) |>
    ungroup()
}

# Process one scenario: load, compute outcomes, join last-year and cumulative,
# then compute NIA/PIA vs baseline. Returns one row per sim.
process_one_scenario <- function(scenario_infos, d_ref) {
  d_sim <- readRDS(scenario_infos$file_path)
  d_sim <- mutate_outcomes(d_sim)
  d_sim <- mutate(
    d_sim,
    scenario_name = scenario_infos$scenario_name
  )

  d_last <- make_last_year_outcomes(d_sim)
  d_cum <- make_cumulative_outcomes(d_sim)

  d <- left_join(
    d_last, d_cum,
    by = c("scenario_name", "batch_number", "sim")
  )

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

# Variant for plots: extract PIA columns and parse scenario name into numeric
# test/treat odds ratios. Assumes scenario names follow the pattern
# "test_{or}_treat_{or}" from make_scenarios.R.
process_one_scenario_plots <- function(
    scenario_infos, d_ref) {
  d_sim <- process_one_scenario(scenario_infos, d_ref)
  d_sim |>
    select(scenario_name, starts_with("cml_pia")) |>
    separate_wider_delim(
      scenario_name, "_",
      names = c(NA, "test", NA, "treat")
    ) |>
    mutate(
      test = as.numeric(test),
      treat = as.numeric(treat)
    )
}
