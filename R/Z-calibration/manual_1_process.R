# TODO: make a single df with |sc_name|targets1 (q2, q1, q3)|

# see 11-calibration process from other projs
# or simply process each sim df

# not sur I need this
process_one_calibration <- function(file_name, nsteps = 52) {
  # keep only the file name without extension and split around `__`
  name_elts <- fs::path_file(file_name) %>%
    fs::path_ext_remove() %>%
    strsplit(split = "__")

  scenario_name <- name_elts[[1]][2]
  batch_num <- as.numeric(name_elts[[1]][3])

  d <- as_tibble(readRDS(file_name))
  d <- d %>%
    filter(time >= max(time) - (nsteps + 52 * 3)) %>% # margin for prep_ret2y
    mutate_calibration_targets() %>%
    filter(time >= max(time) - nsteps) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    mutate(
      scenario_name = scenario_name,
      batch = batch_num
    )

  return(d)
}

d_targets <- EpiModelHIV::mutate_calibration_targets(d_sim, year_steps)
d_dist <- EpiModelHIV::mutate_calibration_distances(d_sim, year_steps)

d <- readRDS("./data/intermediate/calibration/assessments.rds")

glimpse(d)

# Look at the median of the targets for every scenario
d %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  filter(quant == "q2") %>%
  pivot_wider(names_from = scenario_name, values_from = value) %>%
  print(n = 100)

# Look at q1, q2 and q3 for a specific scenario
d %>%
  filter(scenario_name == "1") %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  pivot_wider(names_from = quant, values_from = value) %>%
  print(n = 100)
