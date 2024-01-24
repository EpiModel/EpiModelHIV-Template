# create the elements of the outcomes step by step
mutate_outcomes <- function(d) {
  d %>%
    mutate(
    cc.prep.B  = s_prep__B / s_prep_elig__B,
    cc.prep.H  = s_prep__H / s_prep_elig__H,
    cc.prep.W  = s_prep__W / s_prep_elig__W,
    prep_users = s_prep__B + s_prep__H + s_prep__W
    )
}

# make the outcomes calculated on the same year
make_last_year_outcomes <- function(d) {
  d %>%
    filter(time >= max(time) - 52) %>%
    group_by(scenario_name, batch_number, sim) %>%
    summarise(across(starts_with("cc.prep."), mean)) %>%
    ungroup()
}

# make the outcomes cumulative over the intervention period
make_cumulative_outcomes <- function(d) {
  d %>%
    filter(time >= intervention_start) %>%
    group_by(scenario_name, batch_number, sim) %>%
    summarise(
      cuml_prep_users = sum(prep_users, na.rm = TRUE)
    ) %>%
    ungroup()
}

# each batch of sim is processed in turn
# the output is a data frame with one row per simulation in the batch
# each simulation can be uniquely identified with `scenario_name`,
# `batch_number` and `sim` (all 3 are needed)
process_one_scenario_batch <- function(scenario_infos) {
  sim <- readRDS(scenario_infos$file_name)
  d_sim <- as_tibble(sim)
  d_sim <- mutate_outcomes(d_sim)
  d_sim <- mutate(
    d_sim,
    scenario_name = scenario_infos$scenario_name,
    batch_number = scenario_infos$batch_number
  )

  d_last <- make_last_year_outcomes(d_sim)
  d_cum <- make_cumulative_outcomes(d_sim)

  left_join(d_last, d_cum, by = c("scenario_name", "batch_number", "sim"))
}

